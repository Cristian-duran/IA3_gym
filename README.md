# 🏋️ GymIA - redes LSTM aplicada a la corrección inteligente de ejercicios de peso muerto y sentadilla en gimnasios 

## 📧 Información de Contacto

- **Autor:** Cristian Alejandro Durán Ignacio
- **Email:** duran.cristian@usfx.bo
- **GitHub:** Cristian-duran https://github.com/Cristian-duran

---
## Información del Proyecto

- **Estudiante:** Cristian Alejandro Durán Ignacio
- **Carrera:** Ingenieria en Ciencias de la Computación
- **Universidad:** Universidad Mayor Real y Pontificia San Francisco Xavier de Chuquisaca
- **Curso:** Septimo Semestre
- **Año:** 2025
- **Docente:** Ingeniero Carlos Walter Pacheco Lora

## Descripción del Proyecto

Software completo de inteligencia artificial para la corrección de ejercicios de gimnasio en tiempo real, utilizando análisis de pose con YOLO11 y modelos LSTM para clasificación de movimientos. El software incluye:

- Modelos de entrenamiento para ejercicios de **Peso Muerto** y **Sentadilla**
- Servidor WebRTC optimizado para análisis en tiempo real
- Aplicación móvil Flutter para feedback inmediato por audio

---

## Información de Datasets

### DATASET SENTADILLAS
- 11.190 fotos cadera correcto
- 11.310 fotos cadera incorrecto
- 11.431 fotos rodillas correcto
- 11.177 fotos rodillas incorrecto

**TOTAL DATASET SENTADILLAS:** 45.108 imágenes

### DATASET PESO MUERTO
- 8.342 columna correcto
- 8.301 columna incorrecto
- 8.317 extensión correcto
- 8.205 extensión incorrecto

**TOTAL DATASET PESO MUERTO:** 33.165 imágenes

---

## Guía de Instalación y Ejecución

### Requisitos Previos

- **Python:** 3.8 o superior
- **pip:** gestor de paquetes de Python
- **Git:** para clonar repositorios
- **Jupyter Notebook:** para ejecutar los notebooks
- **Anaconda/Miniconda:** (recomendado para manejo de entornos)

### 🔧 Instalación de Dependencias para Entrenamiento de Modelos

#### 1. Crear Entorno Virtual (Recomendado)

```bash
# Opción 1: Con conda (recomendado)
conda create -n gymia python=3.8
conda activate gymia

# Opción 2: Con venv
python -m venv gymia_env
# En Windows:
gymia_env\Scripts\activate
# En Linux/macOS:
source gymia_env/bin/activate
```

#### 2. Instalar Librerías Necesarias

```bash
# Librerías principales de Machine Learning
pip install tensorflow==2.13.0
pip install keras==2.13.1
pip install scikit-learn==1.3.0

# Librerías para manejo de datos
pip install numpy==1.24.3
pip install pandas==2.0.3
pip install matplotlib==3.7.2

# YOLO y Computer Vision
pip install ultralytics==8.0.196
pip install opencv-python==4.8.0.76

# Jupyter para ejecutar notebooks
pip install jupyter==1.0.0
pip install ipykernel==6.25.0

# Librerías adicionales para análisis
pip install seaborn==0.12.2
pip install plotly==5.15.0
```

#### 3. Verificar Instalación

```bash
python -c "import tensorflow as tf; print('TensorFlow:', tf.__version__)"
python -c "import keras; print('Keras:', keras.__version__)"
python -c "import ultralytics; print('Ultralytics installed successfully')"
```

### 📁 Estructura de Archivos de Entrenamiento

#### Código de Entrenamiento - Peso Muerto
Ubicación: `Codigo_entrenamiento_peso-muerto/`

**Archivos disponibles:**
1. **`Procesamiento.ipynb`** - Procesamiento inicial de imágenes con YOLO11-Pose
2. **`entrenamientolstm.ipynb`** - Entrenamiento del modelo LSTM para peso muerto
3. **`mostrar_prediccion.ipynb`** - Visualización y testing de predicciones

#### Código de Entrenamiento - Sentadilla
Ubicación: `Codigo_entrenamiento_sentadilla/`

**Archivos disponibles:**
1. **`Procesamiento.ipynb`** - Procesamiento inicial de imágenes con YOLO11-Pose
2. **`entrenamientolstm-multiclase.ipynb`** - Entrenamiento del modelo LSTM multiclase para sentadilla
3. **`mostrar_prediccion-prototipo-multiclase.ipynb`** - Visualización y testing de predicciones multiclase

### Pasos para Ejecutar el Entrenamiento

#### 1. Preparar los Datasets
```bash
# Asegúrate de tener los datasets descargados del Drive
# Los archivos .txt deben estar en la ruta especificada en los notebooks
```

#### 2. Ejecutar Procesamiento (Ambos ejercicios)
```bash
# Navegar a la carpeta correspondiente
cd Codigo_entrenamiento_peso-muerto/
# O
cd Codigo_entrenamiento_sentadilla/

# Iniciar Jupyter Notebook
jupyter notebook

# Abrir y ejecutar: Procesamiento.ipynb
```

#### 3. Ejecutar Entrenamiento
```bash
# Para Peso Muerto:
# Abrir y ejecutar: entrenamientolstm.ipynb

# Para Sentadilla:
# Abrir y ejecutar: entrenamientolstm-multiclase.ipynb
```

#### 4. Visualizar Predicciones
```bash
# Para Peso Muerto:
# Abrir y ejecutar: mostrar_prediccion.ipynb

# Para Sentadilla:
# Abrir y ejecutar: mostrar_prediccion-prototipo-multiclase.ipynb
```

### 📝 Notas Importantes sobre los Notebooks

- **Similaridad de archivos:** Los notebooks en ambas carpetas siguen una estructura similar pero con variaciones específicas para cada ejercicio
- **Rutas de archivos:** Asegúrate de actualizar las rutas de los datasets en los notebooks según tu configuración local
- **Timesteps:** Los modelos utilizan diferentes configuraciones de timesteps (30 para peso muerto, 60 para sentadilla)
- **Clases:** Peso muerto maneja 4 clases, sentadilla también maneja múltiples clases para diferentes errores

---

## 🖥️ Servidor Backend (WebRTC)

### Ubicación
Las instrucciones completas para configurar y ejecutar el servidor se encuentran en:

**📁 `GymIA_server_RTC/README.md`**

Este servidor incluye:
- WebRTC para streaming en tiempo real
- Análisis con YOLO11-Pose
- Modelos LSTM entrenados
- API optimizada para dispositivos móviles
- Sistema de feedback por audio

---

## 📱 Aplicación Móvil (Flutter)

### Ubicación
Las instrucciones completas para configurar y ejecutar la aplicación móvil se encuentran en:

**📁 `corrector_gymia_rtc/README.md`**

Esta aplicación incluye:
- Cliente WebRTC para Flutter
- Interfaz minimalista
- Feedback por Text-to-Speech (TTS)
- Soporte para Android e iOS
- Análisis en tiempo real

---

## Troubleshooting Común

### Problemas con TensorFlow/Keras
```bash
# Si hay conflictos con versiones
pip uninstall tensorflow keras
pip install tensorflow==2.13.0 keras==2.13.1
```

### Problemas con YOLO
```bash
# Reinstalar ultralytics
pip uninstall ultralytics
pip install ultralytics==8.0.196
```

### Problemas con Jupyter
```bash
# Registrar el kernel del entorno
python -m ipykernel install --user --name gymia --display-name "GymIA"
```

---

## Soporte

Para problemas específicos:
1. Revisa los README.md específicos de cada componente
2. Verifica que todas las dependencias estén instaladas correctamente
3. Asegúrate de que las rutas de los datasets sean correctas

---
## 📄 Licencia

Este proyecto está licenciado bajo la **Licencia MIT** - ver el archivo [LICENSE](LICENSE) para más detalles.

*Desarrollado con ❤️ para la comunidad fitness y de investigación en IA*
