# Prueba técnica · Análisis de datos con Python (Mirall Hotels)

Análisis de datos de una cadena hotelera ficticia (reservas de 2025) con Python y pandas, centrado en los **canales de venta** y los **tipos de cliente**. Parte de una prueba técnica y se amplió después con visualizaciones más cuidadas, una paleta de colores propia y un análisis más profundo.

## Contenido

* Notebook de Google Colab (`.ipynb`) con la limpieza de datos, el análisis, las visualizaciones y las conclusiones.
* Carpeta `graficos/`: las 5 visualizaciones del análisis en formato PNG, numeradas según el orden de la narrativa.
* Carpeta `tablas_instrucciones/`: los archivos CSV con los datos de partida y el enunciado de la prueba con el diccionario de datos.

## Temas principales

* Carga, limpieza y validación de datos con pandas (formatos de fecha y precio, categorías, nulos y duplicados).
* Unión de varias tablas en una tabla maestra de reservas.
* Reservas sin cliente identificado, tratadas como un grupo propio.
* Cálculo de métricas: ingreso neto tras comisión, tarifa media por noche, porcentaje de reservas no completadas y noches por mes.
* Comparación de canales de venta (directos, OTA, corporativo e intermediario) y de tipos de cliente (Oci y Negocis).
* Visualizaciones con matplotlib y seaborn: cascada, puntos conectados, mapa de calor, burbujas y líneas.
* Uso de una paleta de colores de marca aplicada de forma coherente.
* Conclusiones, dos propuestas de negocio y limitaciones del análisis.

## Visualizaciones

1. Cascada: del valor reservado al ingreso neto.
2. Tarifa por noche bruta vs. neta por canal.
3. Mapa de calor: tipo de cliente y reservas no completadas por canal.
4. Burbujas: comisión vs. reservas no completadas por canal.
5. Líneas: noches por mes de Negocis vs. Oci.

## Nota

Los datos son ficticios y no representan operaciones reales. El notebook está en español, con los títulos de tablas y gráficos en catalán, como en el material original.
