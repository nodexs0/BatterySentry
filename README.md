# Script de Monitoreo de Batería

Este script en Bash monitorea el estado de la batería de un sistema Linux, enviando notificaciones y ajustando el brillo de la pantalla según el nivel de carga de la batería. El objetivo es optimizar el uso de la batería al proporcionar alertas para diferentes estados de la batería y ajustar automáticamente el brillo de la pantalla.

## Máquina de Estados de Batería

El script utiliza una máquina de estados para manejar varios estados de la batería:

![Diagrama de Máquina de Estados](https://raw.githubusercontent.com/nodexs0/BatterySentry/main/assets/image.png)

- **1: Batería Crítica**: El sistema se suspenderá cuando la batería alcance un nivel crítico.
- **2: Batería Muy Baja**: Envía una notificación y reduce el brillo de la pantalla al 5%.
- **3: Batería Baja**: Envía una notificación y reduce el brillo de la pantalla al 20%.
- **4: Batería Suficiente**: No se envía notificación; operación regular.
- **5: Batería Llena**: Envía una notificación cuando la batería está completamente cargada.
- **6: Cargando**: Envía una notificación y aumenta el brillo de la pantalla al 50%.

## Características

- **Notificaciones de Estado de Batería**: Envía notificaciones para estados de batería críticos, muy bajos, bajos, cargando y llenos.
- **Ajuste Automático del Brillo**: Ajusta el brillo de la pantalla según el nivel de batería para conservar energía.
- **Lógica de Máquina de Estados**: Implementa una máquina de estados para gestionar las transiciones entre diferentes estados de la batería.
- **Suspensión del Sistema**: Suspende automáticamente el sistema cuando el nivel de batería alcanza un estado crítico.

## Requisitos

- **ACPI**: El script utiliza el comando `acpi` para obtener información sobre la batería. Asegúrate de tenerlo instalado en tu sistema.
  ```bash
  sudo apt-get install acpi

  sudo pacman -S acpi
  ```

- **Dunst**: El script utiliza `dunstify` para enviar notificaciones. Asegúrate de tenerlo instalado en tu sistema.
  ```bash
  sudo apt-get install dunst

  sudo pacman -S dunst
  ```

- **Brightnessctl**: El script utiliza `brightnessctl` para ajustar el brillo de la pantalla. Asegúrate de tenerlo instalado en tu sistema.
  ```bash
  sudo apt-get install brightnessctl

  sudo pacman -S brightnessctl
  ```

## Instalación

1. Clona el repositorio en tu sistema.
   ```bash
   git clone https://github.com/nodexs0/BatterySentry.git
   ```
2. Cambia al directorio del repositorio.
   ```bash
   cd BatterySentry
   ```
3. Haz que el script sea ejecutable.
   ```bash
   chmod +x battery_sentry.sh
   ```
## Configuración

- **Umbrales de Batería**: Puedes ajustar los umbrales de porcentaje de batería modificando estas variables:
  ```bash
  # Umbrales de Batería
  THRESHOLD_LOW=20         # Umbral de batería baja
  THRESHOLD_VERY_LOW=10    # Umbral de batería muy baja
  THRESHOLD_CRITICAL=2     # Umbral de batería crítica
  THRESHOLD_FULL=85        # Umbral de batería llena
  ```
- **Niveles de Brillo**: Ajusta los niveles de brillo de la pantalla según sea necesario:
  ```bash
  BRIGHTNESS_LOW=3840       # 20% de brillo
  BRIGHTNESS_HIGH=9600      # 50% de brillo
  BRIGHTNESS_VERY_LOW=960   # 5% de brillo
  ```
- **Intervalo de Monitoreo**: El script verifica el estado de la batería cada 30 segundos por defecto. Puedes modificar la frecuencia cambiando la variable FREQUENCY:
  ```bash
  FREQUENCY=30s
  ```
- **Iconos de Notificación**: Personaliza los íconos utilizados en las notificaciones colocando tus íconos en ~/.config/bspwm/assets y actualizando estas variables:
  ```bash
  ICON_DIR="$HOME/.config/bspwm/assets"
  LOW_BATTERY_ICON="$ICON_DIR/low_battery.png"
  CRITICAL_BATTERY_ICON="$ICON_DIR/critical_battery.png"
  CHARGING_ICON="$ICON_DIR/charging.png"
  FULL_BATTERY_ICON="$ICON_DIR/full_battery.png"
  ```

## Uso

Ejecuta el script `battery_sentry.sh` en tu terminal.
   ```bash
   ./battery_sentry.sh &
   ```

Puedes agregar el script a tu archivo de inicio de sesión o en tu administrador de ventanas para que se ejecute automáticamente al iniciar sesión.
```bash
# Agrega esta línea al final de tu archivo de inicio, como .xinitrc, .bash_profile o bspwmrc
/path/to/BatterySentry/battery_sentry.sh &
```

