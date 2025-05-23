# ---- Charger les packages nécessaires ----
library(shiny)
library(shinythemes)  # Pour un thème personnalisé
library(readr)
library(dplyr)
library(ggplot2)
library(DT)
library(janitor)
library(caret)
library(corrplot)  # Pour le graphique de corrélation
library(pROC)      # Pour calculer l'AUC

# ---- Définir le chemin du fichier ----
data_path <- file.path("data", "heart_cleveland_upload.csv")  # Chemin relatif

# ---- Fonction de chargement et prétraitement des données ----
load_and_preprocess_data <- function(file_path) {
  # Vérifier si le fichier existe
  if (!file.exists(file_path)) {
    stop("Erreur : Le fichier ", file_path, " n'existe pas. Vérifiez le chemin.")
  }
  
  # Charger les données
  data <- read_csv(file_path)
  data <- data %>% clean_names()
  
  # Convertir les variables catégorielles en facteurs
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
  
  # Vérifier les valeurs manquantes
  if (any(is.na(data))) {
    warning("Attention : Présence de valeurs manquantes dans les données.")
  }
  
  return(data)
}

# ---- Fonction d'entraînement du modèle ----
train_model <- function(data) {
  features <- c("age", "sex", "chol", "trestbps", "thalach", "cp", "exang", "thal")
  model_data <- data %>%
    select(all_of(features), condition) %>%
    mutate(
      sex = as.numeric(sex) - 1,
      cp = model.matrix(~cp - 1, data = .)[, -1],
      exang = as.numeric(exang) - 1,
      thal = model.matrix(~thal - 1, data = .)[, -1]
    )
  
  set.seed(123)
  model <- train(
    condition ~ .,
    data = model_data,
    method = "glm",
    family = "binomial"
  )
  
  return(model)
}

# ---- Charger les données et entraîner le modèle ----
heart_data <- load_and_preprocess_data(data_path)
model <- train_model(heart_data)

# ---- Lancer l'application ----
source("ui.R")
source("server.R")
shinyApp(ui = ui, server = server)