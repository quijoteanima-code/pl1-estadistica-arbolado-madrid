# Genera arbolado_chamartin_villaverde.csv a partir del fichero completo
# "Arbolado 2026" (CSV, unas 800.000 filas, 71 MB), descargado de
# https://datos.madrid.es/dataset/300761-0-arbolado-especies/downloads
# El fichero completo no va en el proyecto por su tamaño. Para repetir la
# muestra hay que descargarlo, guardarlo como arbolado_full.csv y ejecutar
# este script. PL1_analisis.R solo usa la muestra.

set.seed(2026)

datos_completos <- read.csv2("arbolado_full.csv", fileEncoding = "UTF-8",
                             stringsAsFactors = FALSE)

datos_2distritos <- subset(datos_completos,
                           NBRE_DISTRITO %in% c("CHAMARTIN", "VILLAVERDE"))

# Fuera los árboles sin altura o sin perímetro (12 en Chamartín, 1 en Villaverde)
datos_2distritos <- subset(datos_2distritos,
                           ALTURA_TOTAL != "" & PERIMETRO != "")

# El fichero original usa coma decimal
datos_2distritos$ALTURA_TOTAL <- as.numeric(gsub(",", ".", datos_2distritos$ALTURA_TOTAL))
datos_2distritos$PERIMETRO    <- as.numeric(gsub(",", ".", datos_2distritos$PERIMETRO))

# 100 árboles al azar de cada distrito
chamartin  <- datos_2distritos[datos_2distritos$NBRE_DISTRITO == "CHAMARTIN", ]
villaverde <- datos_2distritos[datos_2distritos$NBRE_DISTRITO == "VILLAVERDE", ]

chamartin  <- chamartin[sample(nrow(chamartin), 100), ]
villaverde <- villaverde[sample(nrow(villaverde), 100), ]

muestra <- rbind(chamartin, villaverde)
muestra <- muestra[, c("ASSETNUM", "NBRE_DISTRITO", "NBRE_BARRIO",
                       "ESPECIE", "PERIMETRO", "ALTURA_TOTAL")]
names(muestra) <- c("id_arbol", "distrito", "barrio", "especie",
                    "perimetro_tronco_cm", "altura_total_m")

write.csv(muestra, "arbolado_chamartin_villaverde.csv", row.names = FALSE,
          fileEncoding = "UTF-8")

cat("Muestra generada con", nrow(muestra), "árboles\n")
print(table(muestra$distrito))
