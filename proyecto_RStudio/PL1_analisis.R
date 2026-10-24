# PL1 - Estadística descriptiva
# Altura total de los árboles (m) en Chamartín y Villaverde
# Datos: https://datos.madrid.es/dataset/300761-0-arbolado-especies/downloads
# La muestra se genera con 00_preparar_muestra.R

if (!require("ggplot2")) install.packages("ggplot2")
library(ggplot2)
if (!require("plotly")) install.packages("plotly")
library(plotly)
if (!require("htmlwidgets")) install.packages("htmlwidgets")
library(htmlwidgets)
if (!require("e1071")) install.packages("e1071")
library(e1071)

# Fuera de RStudio, saveWidget necesita saber dónde está pandoc
if (Sys.getenv("RSTUDIO_PANDOC") == "") {
  Sys.setenv(RSTUDIO_PANDOC = "C:/Program Files/RStudio/resources/app/bin/quarto/bin/tools")
}

datos <- read.csv("arbolado_chamartin_villaverde.csv", stringsAsFactors = FALSE,
                  fileEncoding = "UTF-8")
datos$distrito <- factor(datos$distrito, levels = c("CHAMARTIN", "VILLAVERDE"),
                         labels = c("Chamartín", "Villaverde"))

# 3.1 Muestras
n_total <- nrow(datos)
n_grupo <- table(datos$distrito)
cat("Tamaño de la muestra:", n_total, "\n")
print(n_grupo)

# 3.2 Medidas estadísticas
# R no trae función para la moda
moda <- function(x) {
  ux <- unique(x)
  ux[which.max(tabulate(match(x, ux)))]
}

medidas <- function(x) {
  c(n           = length(x),
    media       = mean(x),
    mediana     = median(x),
    moda        = moda(x),
    desv_tipica = sd(x),
    varianza    = var(x),
    cv_pct      = 100 * sd(x) / mean(x),
    minimo      = min(x),
    q1          = quantile(x, 0.25, names = FALSE),
    q3          = quantile(x, 0.75, names = FALSE),
    maximo      = max(x),
    rango       = max(x) - min(x),
    riq         = IQR(x),
    asimetria   = skewness(x),
    curtosis    = kurtosis(x))   # e1071: curtosis de exceso, la normal vale 0
}

tabla1 <- round(sapply(split(datos$altura_total_m, datos$distrito), medidas), 2)
print(tabla1)
write.csv(tabla1, "tabla1_medidas_estadisticas.csv")

tabla1_total <- round(medidas(datos$altura_total_m), 2)
print(tabla1_total)
write.csv(as.data.frame(tabla1_total), "tabla1b_medidas_totales.csv")

# Árboles atípicos según el criterio del diagrama de cajas (1,5 * RIQ)
for (d in levels(datos$distrito)) {
  x <- datos$altura_total_m[datos$distrito == d]
  limite <- quantile(x, 0.75) + 1.5 * IQR(x)
  cat(d, "- atípicos por encima de", round(limite, 2), "m:", sort(x[x > limite]), "\n")
}

# 3.3 Tablas de contingencia: altura agrupada en tres tramos
datos$altura_categoria <- cut(datos$altura_total_m,
                              breaks = c(-Inf, 5, 10, Inf),
                              labels = c("Baja (<= 5 m)", "Media (> 5 y <= 10 m)", "Alta (> 10 m)"))

tabla2 <- table(datos$distrito, datos$altura_categoria)
print(addmargins(tabla2))
write.csv(as.data.frame.matrix(addmargins(tabla2)), "tabla2_contingencia.csv")

tabla3 <- round(100 * prop.table(tabla2, margin = 1), 1)
print(tabla3)
write.csv(as.data.frame.matrix(tabla3), "tabla3_contingencia_pct.csv")

# 3.4 Diagramas
fig1 <- ggplot(datos, aes(x = altura_total_m, fill = distrito)) +
  geom_histogram(binwidth = 1, color = "white", alpha = 0.8) +
  facet_wrap(~ distrito, ncol = 1) +
  labs(title = "Figura 1. Histograma de la altura total del árbol por distrito",
       x = "Altura total (m)", y = "Número de árboles", fill = "Distrito") +
  theme_minimal()
print(fig1)
ggsave("figura1_histograma.png", fig1, width = 7, height = 5, dpi = 150)

fig2 <- ggplot(datos, aes(x = distrito, y = altura_total_m, fill = distrito)) +
  geom_boxplot(outlier.color = "red") +
  labs(title = "Figura 2. Diagrama de cajas de la altura total del árbol por distrito",
       x = "Distrito", y = "Altura total (m)") +
  theme_minimal() + theme(legend.position = "none")
print(fig2)
ggsave("figura2_boxplot.png", fig2, width = 6, height = 5, dpi = 150)

tabla2_df <- as.data.frame(tabla2)
names(tabla2_df) <- c("distrito", "altura_categoria", "frecuencia")
fig3 <- ggplot(tabla2_df, aes(x = altura_categoria, y = frecuencia, fill = distrito)) +
  geom_col(position = "dodge") +
  labs(title = "Figura 3. Número de árboles por tramo de altura y distrito",
       x = "Tramo de altura", y = "Número de árboles", fill = "Distrito") +
  theme_minimal()
print(fig3)
ggsave("figura3_barras.png", fig3, width = 7, height = 5, dpi = 150)

fig4 <- ggplot(datos, aes(x = altura_total_m, fill = distrito)) +
  geom_density(alpha = 0.5) +
  labs(title = "Figura 4. Densidad de la altura total del árbol por distrito",
       x = "Altura total (m)", y = "Densidad", fill = "Distrito") +
  theme_minimal()
print(fig4)
ggsave("figura4_densidad.png", fig4, width = 7, height = 5, dpi = 150)

# Diagramas interactivos con plotly (se abren en el navegador)
fig5 <- plot_ly(datos, x = ~distrito, y = ~altura_total_m, color = ~distrito,
                type = "box", boxpoints = "all", jitter = 0.3, pointpos = 0) %>%
  layout(title = "Figura 5. Diagrama de cajas interactivo de la altura total del árbol",
         xaxis = list(title = "Distrito"),
         yaxis = list(title = "Altura total (m)"))
print(fig5)
saveWidget(fig5, "figura5_boxplot_interactivo.html", selfcontained = TRUE)

fig6 <- plot_ly(datos, x = ~altura_total_m, color = ~distrito,
                type = "histogram", alpha = 0.7, nbinsx = 20) %>%
  layout(barmode = "overlay",
         title = "Figura 6. Histograma interactivo de la altura total del árbol",
         xaxis = list(title = "Altura total (m)"),
         yaxis = list(title = "Número de árboles"))
print(fig6)
saveWidget(fig6, "figura6_histograma_interactivo.html", selfcontained = TRUE)
