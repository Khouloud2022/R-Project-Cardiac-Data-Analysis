# Heart Disease Analysis Shiny App

This Shiny application provides an interactive interface for exploratory data analysis and prediction of heart disease using the Cleveland heart disease dataset. Built as part of a CRISP-DM project, it enables users to visualize data, evaluate multiple machine learning models, and predict heart disease risk with robust error handling.

## Features

- **Model Selection**: Choose between logistic regression (`glm`), random forest (`rf`), or SVM (`svm`) models.
- **Data Visualizations**: Histograms, boxplots, density plots, and interactive scatter plots (via `plotly`) for variables like age, cholesterol, and heart rate.
- **Statistical Summaries**: Summary statistics for selected variables.
- **Correlation Analysis**: Heatmap of correlations among numeric variables.
- **Model Evaluation**: Metrics (accuracy, sensitivity, specificity, AUC) with train/test split and confusion matrix.
- **Variable Importance**: Bar plot of feature importance for the selected model.
- **ROC Curve**: Visualization of model performance.
- **Predictions**: Interactive interface to predict heart disease risk for new patients.
- **Data Export**: Download filtered data as CSV or plots as PNG.
- **Error Handling**: Comprehensive error catching and user-friendly messages for invalid inputs, model failures, or data issues.

## Installation

### Prerequisites

- **R**: Version 4.0 or higher (check with `R.version.string`).
- **RStudio**: Recommended for running the app.
- **Dataset**: The Cleveland heart disease dataset (`heart_cleveland_upload.csv`) is required.

### R Packages

Install the required packages:

```R
install.packages(c("shiny", "shinythemes", "readr", "dplyr", "ggplot2", "DT", "janitor", "caret", "corrplot", "pROC", "plotly", "randomForest", "e1071"))
```

## Setup

1. **Clone the Repository**:

   ```bash
   git clone <repository-url>
   cd <repository-directory>
   ```

2. **Directory Structure**:

   - Place `heart_cleveland_upload.csv` in the `data/` subfolder.
   - Ensure the following files are in the root directory:
     - `app.R`: Main script to load data, train models, and launch the app.
     - `ui.R`: User interface definition.
     - `server.R`: Server logic for reactivity and outputs.
     - `app_single.R`: Alternative single-file version combining `app.R`, `ui.R`, and `server.R`.

3. **Verify Dataset**:

   - Confirm `data/heart_cleveland_upload.csv` exists:

     ```R
     list.files("data")
     ```
   - If the dataset is elsewhere, update `data_path` in `app.R` or `app_single.R`.

## Usage

### Running the App

1. **Multi-File Version**:

   - Open `app.R` in RStudio.
   - Set the working directory:

     ```R
     setwd("<path-to-repository>")
     ```
   - Click "Run App" or run:

     ```R
     source("app.R")
     ```
   - The app will open in a browser (e.g., `http://127.0.0.1:5183`).

2. **Single-File Version**:

   - Use `app_single.R` if sourcing issues occur (e.g., `ui.R` not found).
   - Open `app_single.R` and run as above.

### Interacting with the App

- **Sidebar**:
  - Select a model (`glm`, `rf`, `svm`).
  - Choose a variable (e.g., `age`, `chol`) and plot type (histogram, boxplot, density).
  - Filter by age range or segment by condition (heart disease presence/absence).
  - Select X/Y variables for the scatter plot.
  - Export filtered data (CSV) or plots (PNG).
- **Tabs**:
  - **Visualisation**: View plots of selected variables.
  - **Résumé**: See statistical summaries.
  - **Tableau**: Explore the dataset interactively.
  - **Corrélation**: Analyze variable correlations.
  - **Métriques du Modèle**: Review model performance metrics (fixed to handle factor levels).
  - **Importance des Variables**: Check feature importance for the selected model.
  - **Courbe ROC**: Visualize the ROC curve.
  - **Scatter Plot**: Interact with a `plotly` scatter plot (hover for details).
  - **Prédiction**: Input patient data to predict heart disease risk (fixed for reliable predictions).



## Troubleshooting

- **Error: "impossible de trouver la fonction 'confusionMatrix'"**:

  - Ensure `caret` is installed and loaded:

    ```R
    install.packages("caret")
    library(caret)
    ```
  - Use `caret::confusionMatrix` in `server.R` to avoid conflicts.

- **Error: "**`data` **and** `reference` **should be factors with the same levels"**:

  - Fixed by ensuring predictions and true labels are factors with levels `Absence`, `Présence`.
  - Check the "Métriques du Modèle" tab for debugging output (factor levels).
  - Verify `heart_cleveland_upload.csv` has a `condition` column with values `0` or `1`.

- **Prediction Errors**:

  - Ensure input values are within valid ranges (e.g., age 29–77).
  - Check the "Prédiction" tab for error messages if the model fails.

- **Sourcing Issues**:

  - If `ui.R` or `server.R` are not found, ensure they are in the same directory as `app.R`.
  - Use `app_single.R` to avoid sourcing issues.

- **Dataset Path**:

  - If `heart_cleveland_upload.csv` is not in `data/`, update `data_path` in `app.R` or `app_single.R`.



## Acknowledgments

- **Dataset**: Cleveland heart disease dataset from UCI Machine Learning Repository.
- **Tools**: Built with R, Shiny, and packages like `caret`, `ggplot2`, `plotly`, `randomForest`, and `e1071`.
