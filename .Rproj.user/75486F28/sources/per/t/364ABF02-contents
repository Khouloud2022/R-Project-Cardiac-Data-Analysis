library(shiny)
library(shinythemes)
library(ggplot2)
library(dplyr)
library(DT)

# Interface utilisateur
ui <- fluidPage(
  theme = shinytheme("cerulean"),  # Thème personnalisé
  titlePanel("Analyse des Données Cardiaques"),
  sidebarLayout(
    sidebarPanel(
      selectInput("variable", "Choisir une variable:",
                  choices = c("age", "sex", "chol", "trestbps", "thalach")),
      selectInput("plot_type", "Type de graphique:",
                  choices = c("Histogramme", "Boxplot", "Densité")),
      checkboxInput("by_condition", "Segmenter par condition", value = TRUE),
      sliderInput("age_range", "Plage d’âge:",
                  min = 29, max = 77, value = c(29, 77)),
      # Ajout pour le scatter plot
      selectInput("x_var", "Variable X (Scatter):", choices = c("age", "chol", "trestbps", "thalach")),
      selectInput("y_var", "Variable Y (Scatter):", choices = c("chol", "age", "trestbps", "thalach")),
      # Bouton pour exporter
      downloadButton("download_data", "Exporter les données (CSV)"),
      downloadButton("download_plot", "Exporter le graphique (PNG)")
    ),
    mainPanel(
      tabsetPanel(
        tabPanel("Visualisation", plotOutput("plot")),
        tabPanel("Résumé", verbatimTextOutput("summary")),
        tabPanel("Tableau", DTOutput("table")),
        tabPanel("Corrélation", plotOutput("corr_plot")),
        tabPanel("Métriques du Modèle", verbatimTextOutput("model_metrics")),
        tabPanel("Scatter Plot", plotOutput("scatter_plot")),
        tabPanel("Prédiction",
                 h3("Prédire la Maladie Cardiaque"),
                 numericInput("pred_age", "Âge:", value = 50, min = 29, max = 77),
                 selectInput("pred_sex", "Sexe:", choices = c("Femme", "Homme")),
                 numericInput("pred_chol", "Cholestérol (mg/dl):", value = 200, min = 126, max = 564),
                 numericInput("pred_trestbps", "Pression artérielle (mm Hg):", value = 120, min = 94, max = 200),
                 numericInput("pred_thalach", "Fréq. cardiaque max:", value = 150, min = 71, max = 202),
                 selectInput("pred_cp", "Douleur thoracique:",
                             choices = c("Typique", "Atypique", "Douleur non angineuse", "Asymptomatique")),
                 selectInput("pred_exang", "Angine à l’effort:", choices = c("Non", "Oui")),
                 selectInput("pred_thal", "Test de thallium:",
                             choices = c("Normal", "Défaut fixe", "Défaut réversible")),
                 actionButton("predict", "Prédire"),
                 verbatimTextOutput("prediction")
        )
      )
    )
  )
)