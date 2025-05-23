library(shiny)
library(ggplot2)
library(dplyr)
library(DT)
library(corrplot)
library(pROC)

server <- function(input, output, session) {
  # Données filtrées
  filtered_data <- reactive({
    validate(
      need(input$age_range[1] >= 29 && input$age_range[2] <= 77, "Plage d’âge invalide.")
    )
    heart_data %>%
      filter(age >= input$age_range[1] & age <= input$age_range[2])
  })
  
  # Visualisation principale
  output$plot <- renderPlot({
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
  })
  
  # Résumé statistique
  output$summary <- renderPrint({
    summary(filtered_data()[, input$variable, drop = FALSE])
  })
  
  # Tableau interactif
  output$table <- renderDT({
    datatable(filtered_data(), options = list(pageLength = 5))
  })
  
  # Graphique de corrélation
  output$corr_plot <- renderPlot({
    numeric_data <- heart_data %>%
      select(age, trestbps, chol, thalach, oldpeak, ca) %>%
      as.matrix()
    corr <- cor(numeric_data, use = "complete.obs")
    corrplot(corr, method = "color", type = "upper", tl.col = "black", tl.srt = 45,
             addCoef.col = "black", number.cex = 0.7)
  })
  
  # Métriques du modèle
  output$model_metrics <- renderPrint({
    pred <- predict(model, newdata = model$trainingData, type = "raw")
    cm <- confusionMatrix(pred, model$trainingData$condition)
    roc_obj <- roc(as.numeric(model$trainingData$condition == "Présence"),
                   as.numeric(pred == "Présence"))
    cat("Métriques du Modèle (sur données d'entraînement) :\n")
    cat(sprintf("Précision : %.2f%%\n", cm$overall["Accuracy"] * 100))
    cat(sprintf("Sensibilité : %.2f%%\n", cm$byClass["Sensitivity"] * 100))
    cat(sprintf("Spécificité : %.2f%%\n", cm$byClass["Specificity"] * 100))
    cat(sprintf("AUC : %.3f\n", auc(roc_obj)))
    cat("\nMatrice de Confusion :\n")
    print(cm$table)
  })
  
  # Scatter Plot
  output$scatter_plot <- renderPlot({
    data <- filtered_data()
    ggplot(data, aes(x = .data[[input$x_var]], y = .data[[input$y_var]], color = condition)) +
      geom_point(size = 3, alpha = 0.6) +
      theme_minimal() +
      labs(title = paste(input$y_var, "vs", input$x_var), x = input$x_var, y = input$y_var)
  })
  
  # Prédiction avec validation
  observeEvent(input$predict, {
    # Validation des entrées
    validate(
      need(input$pred_age >= 29 && input$pred_age <= 77, "Âge doit être entre 29 et 77."),
      need(input$pred_chol >= 126 && input$pred_chol <= 564, "Cholestérol doit être entre 126 et 564."),
      need(input$pred_trestbps >= 94 && input$pred_trestbps <= 200, "Pression doit être entre 94 et 200."),
      need(input$pred_thalach >= 71 && input$pred_thalach <= 202, "Fréquence cardiaque doit être entre 71 et 202.")
    )
    
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
        cp_Atypique = as.numeric(cp == "Atypique"),
        cp_Douleur_non_angineuse = as.numeric(cp == "Douleur non angineuse"),
        cp_Asymptomatique = as.numeric(cp == "Asymptomatique"),
        exang = as.numeric(exang == "Oui"),
        thal_Défaut_fixe = as.numeric(thal == "Défaut fixe"),
        thal_Défaut_réversible = as.numeric(thal == "Défaut réversible")
      ) %>%
      select(-cp, -thal)
    
    pred <- predict(model, newdata = new_data, type = "prob")
    
    output$prediction <- renderPrint({
      prob <- pred[1, "Présence"]
      cat(sprintf("Probabilité de maladie : %.2f%%\n", prob * 100))
      cat("Classification : ", ifelse(prob >= 0.5, "Présence", "Absence"), "\n")
    })
  })
  
  # Exporter les données
  output$download_data <- downloadHandler(
    filename = function() { "heart_data_filtered.csv" },
    content = function(file) { write_csv(filtered_data(), file) }
  )
  
  # Exporter le graphique
  output$download_plot <- downloadHandler(
    filename = function() { "plot.png" },
    content = function(file) {
      ggsave(file, plot = last_plot(), device = "png", width = 8, height = 6)
    }
  )
}