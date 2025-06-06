library(shiny)
library(ggplot2)
library(dplyr)
library(DT)
library(corrplot)
library(pROC)
library(caret)
library(plotly)

server <- function(input, output, session) {
  # Données filtrées
  filtered_data <- reactive({
    validate(
      need(input$age_range[1] >= 29 && input$age_range[2] <= 77, "Plage d’âge invalide (29–77)."),
      need(input$age_range[1] <= input$age_range[2], "L’âge minimum doit être inférieur ou égal à l’âge maximum.")
    )
    tryCatch({
      heart_data %>%
        filter(age >= input$age_range[1] & age <= input$age_range[2])
    }, error = function(e) {
      stop("Erreur lors du filtrage des données : ", conditionMessage(e))
    })
  })
  
  # Visualisation principale
  output$plot <- renderPlot({
    tryCatch({
      data <- filtered_data()
      if (input$plot_type == "Histogramme") {
        p <- ggplot(data, aes(x = .data[[input$variable]]))
        if (input$by_condition) {
          p <- p + geom_histogram(aes(fill = condition), position = "dodge", bins = 30)
        } else {
          p <- p + geom_histogram(fill = "skyblue", bins = 30)
        }
      } else if (input$plot_type == "Boxplot") {
        if (input$by_condition) {
          p <- ggplot(data, aes(x = condition, y = .data[[input$variable]], fill = condition))
        } else {
          p <- ggplot(data, aes(y = .data[[input$variable]]))
        }
        p <- p + geom_boxplot()
      } else {
        p <- ggplot(data, aes(x = .data[[input$variable]]))
        if (input$by_condition) {
          p <- p + geom_density(aes(fill = condition), alpha = 0.5)
        } else {
          p <- p + geom_density(fill = "skyblue", alpha = 0.5)
        }
      }
      p + theme_minimal() + labs(title = paste("Distribution de", input$variable))
    }, error = function(e) {
      stop("Erreur lors de la génération du graphique : ", conditionMessage(e))
    })
  })
  
  # Résumé statistique
  output$summary <- renderPrint({
    tryCatch({
      summary(filtered_data()[, input$variable, drop = FALSE])
    }, error = function(e) {
      cat("Erreur lors du calcul du résumé : ", conditionMessage(e), "\n")
    })
  })
  
  # Tableau interactif
  output$table <- renderDT({
    tryCatch({
      datatable(filtered_data(), options = list(pageLength = 5))
    }, error = function(e) {
      stop("Erreur lors de la génération du tableau : ", conditionMessage(e))
    })
  })
  
  # Graphique de corrélation
  output$corr_plot <- renderCachedPlot({
    tryCatch({
      numeric_data <- heart_data %>%
        select(age, trestbps, chol, thalach, oldpeak, ca) %>%
        as.matrix()
      corr <- cor(numeric_data, use = "complete.obs")
      corrplot(corr, method = "color", type = "upper", tl.col = "black", tl.srt = 45,
               addCoef.col = "black", number.cex = 0.7)
    }, error = function(e) {
      stop("Erreur lors de la génération du graphique de corrélation : ", conditionMessage(e))
    })
  }, cacheKeyExpr = { list("corr_plot") })
  
  # Métriques du modèle
  output$model_metrics <- renderPrint({
    tryCatch({
      model <- models[[input$model_type]]
      if (is.null(model)) {
        stop("Modèle non disponible : ", input$model_type)
      }
      
      # Vérifier les niveaux des facteurs
      if (!is.factor(test_data$condition)) {
        test_data$condition <<- factor(test_data$condition, levels = c("Absence", "Présence"))
      }
      
      pred <- predict(model, newdata = test_data, type = "raw")
      pred <- factor(pred, levels = levels(test_data$condition))
      
      # Vérification des niveaux
      message("Niveaux de pred : ", paste(levels(pred), collapse = ", "))
      message("Niveaux de test_data$condition : ", paste(levels(test_data$condition), collapse = ", "))
      
      if (!identical(levels(pred), levels(test_data$condition))) {
        stop("Les niveaux de pred et test_data$condition ne correspondent pas.")
      }
      
      cm <- caret::confusionMatrix(pred, test_data$condition)
      roc_obj <- roc(as.numeric(test_data$condition == "Présence"),
                     as.numeric(predict(model, test_data, type = "prob")[,"Présence"]))
      
      cat("Métriques du Modèle (", input$model_type, ") sur données de test :\n")
      cat(sprintf("Précision : %.2f%%\n", cm$overall["Accuracy"] * 100))
      cat(sprintf("Sensibilité : %.2f%%\n", cm$byClass["Sensitivity"] * 100))
      cat(sprintf("Spécificité : %.2f%%\n", cm$byClass["Specificity"] * 100))
      cat(sprintf("AUC : %.3f\n", auc(roc_obj)))
      cat("\nMatrice de Confusion :\n")
      print(cm$table)
    }, error = function(e) {
      cat("Erreur dans le calcul des métriques : ", conditionMessage(e), "\n")
      cat("Vérifiez les données de test et le modèle sélectionné.\n")
    })
  })
  
  # Importance des variables
  output$var_imp_plot <- renderPlot({
    tryCatch({
      model <- models[[input$model_type]]
      if (is.null(model)) {
        stop("Modèle non disponible : ", input$model_type)
      }
      imp <- varImp(model, scale = TRUE)
      plot(imp, main = paste("Importance des Variables (", input$model_type, ")"), top = 8)
    }, error = function(e) {
      stop("Erreur lors de la génération du graphique d'importance : ", conditionMessage(e))
    })
  })
  
  # Courbe ROC
  output$roc_plot <- renderCachedPlot({
    tryCatch({
      model <- models[[input$model_type]]
      if (is.null(model)) {
        stop("Modèle non disponible : ", input$model_type)
      }
      roc_obj <- roc(as.numeric(test_data$condition == "Présence"),
                     as.numeric(predict(model, test_data, type = "prob")[,"Présence"]))
      plot(roc_obj, main = paste("Courbe ROC (", input$model_type, ")"), print.auc = TRUE)
    }, error = function(e) {
      stop("Erreur lors de la génération de la courbe ROC : ", conditionMessage(e))
    })
  }, cacheKeyExpr = { list(input$model_type, "roc_plot") })
  
  # Scatter Plot interactif avec plotly
  output$scatter_plot <- renderPlotly({
    tryCatch({
      data <- filtered_data()
      plot_ly(data, x = ~.data[[input$x_var]], y = ~.data[[input$y_var]], color = ~condition,
              type = "scatter", mode = "markers", marker = list(size = 10, opacity = 0.6)) %>%
        layout(title = paste(input$y_var, "vs", input$x_var),
               xaxis = list(title = input$x_var),
               yaxis = list(title = input$y_var))
    }, error = function(e) {
      stop("Erreur lors de la génération du scatter plot : ", conditionMessage(e))
    })
  })
  
  # Prédiction avec validation
  observeEvent(input$predict, {
    tryCatch({
      validate(
        need(input$pred_age >= 29 && input$pred_age <= 77, "Âge doit être entre 29 et 77."),
        need(input$pred_chol >= 126 && input$pred_chol <= 564, "Cholestérol doit être entre 126 et 564."),
        need(input$pred_trestbps >= 94 && input$pred_trestbps <= 200, "Pression doit être entre 94 et 200."),
        need(input$pred_thalach >= 71 && input$pred_thalach <= 202, "Fréquence cardiaque doit être entre 71 et 202.")
      )
      
      model <- models[[input$model_type]]
      if (is.null(model)) {
        stop("Modèle non disponible : ", input$model_type)
      }
      
      new_data <- data.frame(
        age = input$pred_age,
        sex = input$pred_sex,
        chol = input$pred_chol,
        trestbps = input$pred_trestbps,
        thalach = input$pred_thalach,
        cp = input$pred_cp,
        exang = input$pred_exang,
        thal = input$pred_thal
      ) %>%
        mutate(
          sex = as.numeric(sex == "Homme"),
          exang = as.numeric(exang == "Oui"),
          cp_Atypique = as.numeric(cp == "Atypique"),
          cp_Douleur_non_angineuse = as.numeric(cp == "Douleur non angineuse"),
          cp_Asymptomatique = as.numeric(cp == "Asymptomatique"),
          thal_Défaut_fixe = as.numeric(thal == "Défaut fixe"),
          thal_Défaut_réversible = as.numeric(thal == "Défaut réversible")
        ) %>%
        select(age, sex, chol, trestbps, thalach, exang,
               cp_Atypique, cp_Douleur_non_angineuse, cp_Asymptomatique,
               thal_Défaut_fixe, thal_Défaut_réversible)
      
      pred <- predict(model, newdata = new_data, type = "prob")
      
      output$prediction <- renderPrint({
        prob <- pred[1, "Présence"]
        cat(sprintf("Probabilité de maladie (modèle %s) : %.2f%%\n", input$model_type, prob * 100))
        cat("Classification : ", ifelse(prob >= 0.5, "Présence", "Absence"), "\n")
      })
    }, error = function(e) {
      output$prediction <- renderPrint({
        cat("Erreur lors de la prédiction : ", conditionMessage(e), "\n")
        cat("Vérifiez les entrées et le modèle sélectionné.\n")
      })
    })
  })
  
  # Exporter les données
  output$download_data <- downloadHandler(
    filename = function() { "heart_data_filtered.csv" },
    content = function(file) {
      tryCatch({
        write_csv(filtered_data(), file)
      }, error = function(e) {
        stop("Erreur lors de l'exportation des données : ", conditionMessage(e))
      })
    }
  )
  
  # Exporter le graphique
  output$download_plot <- downloadHandler(
    filename = function() { "plot.png" },
    content = function(file) {
      tryCatch({
        ggsave(file, plot = ggplot2::last_plot(), device = "png", width = 8, height = 6)
      }, error = function(e) {
        stop("Erreur lors de l'exportation du graphique : ", conditionMessage(e))
      })
    }
  )
}