# ---- Charger les packages nécessaires ----
library(shiny)
library(shinythemes)
library(readr)
library(dplyr)
library(ggplot2)
library(DT)
library(janitor)
library(caret)
library(corrplot)
library(pROC)
library(plotly)
library(randomForest)  # Pour le modèle rf
library(e1071)        # Pour le modèle svm

# ---- Définir le chemin du fichier ----
data_path <- file.path("data", "heart_cleveland_upload.csv")

# ---- Fonction de chargement et prétraitement des données ----
load_and_preprocess_data <- function(file_path) {
  tryCatch({
    if (!file.exists(file_path)) {
      stop("Erreur : Le fichier ", file_path, " n'existe pas. Vérifiez le chemin.")
    }
    
    data <- read_csv(file_path)
    data <- data %>% clean_names()
    
    data <- data %>%
      mutate(
        sex = factor(sex, levels = c(0, 1), labels = c("Femme", "Homme")),
        cp = factor(cp, levels = 0:3, labels = c("Typique", "Atypique", "Douleur non angineuse", "Asymptomatique")),
        fbs = factor(fbs, levels = c(0, 1), labels = c("<= 120 mg/dl", "> 120 mg/dl")),
        restecg = factor(restecg, levels = 0:2, labels = c("Normal", "Anomalie onde ST-T", "Hypertrophie ventriculaire")),
        exang = factor(exang, levels = c(0, 1), labels = c("Non", "Oui")),
        slope = factor(slope, levels = 0:2, labels = c("Descente", "Plate", "Montée")),
        thal = factor(thal, levels = c(0, 1, 2), labels = c("Normal", "Défaut fixe", "Défaut réversible")),
        condition = factor(condition, levels = c(0, 1), labels = c("Absence", "Présence"))
      )
    
    if (any(is.na(data))) {
      warning("Attention : Présence de valeurs manquantes dans les données.")
    }
    
    message("Données chargées avec succès. Dimensions : ", nrow(data), " lignes, ", ncol(data), " colonnes.")
    return(data)
  }, error = function(e) {
    stop("Erreur lors du chargement des données : ", conditionMessage(e))
  })
}

# ---- Fonction de préparation des données pour le modèle ----
prepare_model_data <- function(data) {
  tryCatch({
    features <- c("age", "sex", "chol", "trestbps", "thalach", "cp", "exang", "thal")
    model_data <- data %>%
      select(all_of(features), condition) %>%
      mutate(
        sex = as.numeric(sex == "Homme"),
        exang = as.numeric(exang == "Oui")
      )
    
    # Créer des variables dummy pour cp et thal
    cp_dummy <- model.matrix(~cp - 1, data = model_data) %>% as.data.frame()
    thal_dummy <- model.matrix(~thal - 1, data = model_data) %>% as.data.frame()
    
    # Renommer les colonnes pour correspondre à l'entraînement
    colnames(cp_dummy) <- c("cp_Typique", "cp_Atypique", "cp_Douleur_non_angineuse", "cp_Asymptomatique")
    colnames(thal_dummy) <- c("thal_Normal", "thal_Défaut_fixe", "thal_Défaut_réversible")
    
    # Combiner et supprimer les colonnes originales
    model_data <- model_data %>%
      bind_cols(cp_dummy[, -1], thal_dummy[, -1]) %>%
      select(-cp, -thal)
    
    message("Données préparées pour le modèle. Colonnes : ", paste(colnames(model_data), collapse = ", "))
    return(model_data)
  }, error = function(e) {
    stop("Erreur lors de la préparation des données : ", conditionMessage(e))
  })
}

# ---- Fonction d'entraînement des modèles ----
train_models <- function(data) {
  tryCatch({
    model_data <- prepare_model_data(data)
    
    # Séparer en train/test
    set.seed(123)
    train_idx <- createDataPartition(model_data$condition, p = 0.8, list = FALSE)
    train_data <- model_data[train_idx, ]
    test_data <- model_data[-train_idx, ]
    
    if (nrow(test_data) == 0) {
      stop("Erreur : Ensemble de test vide. Augmentez la taille des données.")
    }
    
    # Entraîner plusieurs modèles
    models <- list(
      glm = train(
        condition ~ ., data = train_data, method = "glm", family = "binomial",
        trControl = trainControl(method = "cv", number = 5)
      ),
      rf = train(
        condition ~ ., data = train_data, method = "rf",
        trControl = trainControl(method = "cv", number = 5)
      )
    )
    
    message("Modèles entraînés : ", paste(names(models), collapse = ", "))
    return(list(models = models, train_data = train_data, test_data = test_data))
  }, error = function(e) {
    stop("Erreur lors de l'entraînement des modèles : ", conditionMessage(e))
  })
}

# ---- Charger les données et entraîner les modèles ----
heart_data <- load_and_preprocess_data(data_path)
model_results <- train_models(heart_data)
models <- model_results$models
train_data <- model_results$train_data
test_data <- model_results$test_data

# ---- Lancer l'application ----
source("ui.R")
source("server.R")
shinyApp(ui = ui, server = server)