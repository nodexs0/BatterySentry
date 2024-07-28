#!/bin/bash

# Umbrales de batería
THRESHOLD_LOW=20
THRESHOLD_VERY_LOW=10
THRESHOLD_CRITICAL=2
THRESHOLD_FULL=85

# Brillo de pantalla
BRIGHTNESS_LOW=3840 # 20%
BRIGHTNESS_HIGH=9600 # 50%
BRIGHTNESS_VERY_LOW=960 # 5%
FREQUENCY=30s

# Ruta de los iconos
ICON_DIR="$HOME/.config/bspwm/assets"
LOW_BATTERY_ICON="$ICON_DIR/low_battery.png"
CRITICAL_BATTERY_ICON="$ICON_DIR/critical_battery.png"
CHARGING_ICON="$ICON_DIR/charging.png"
FULL_BATTERY_ICON="$ICON_DIR/full_battery.png"

# Archivos temporales
FULL_FILE="/tmp/battery_full"
LOW_FILE="/tmp/battery_low"
CRITICAL_FILE="/tmp/battery_critical"
VERY_LOW_FILE="/tmp/battery_very_low"
CHARGING_FILE="/tmp/battery_charging"
DISCHARGING_FILE="/tmp/battery_discharging"

# Sonido de notificación
NOTIFICATION_SOUND="$HOME/.config/bspwm/assets/notification.mp3"

# Función para enviar notificaciones
send_notification() {
    local message=$1
    local icon=$2
    dunstify "$message" -i "$icon" -u critical -t 5000

    # Reproducir sonido de notificación con mpg123
    if [ -f "$NOTIFICATION_SOUND" ]; then
        mpg123 -q "$NOTIFICATION_SOUND" &
    fi
}

# Maquina de estados
# 1: Batería crítica
# 2: Batería muy baja
# 3: Batería baja
# 4: Batería suficiente ( No se requiere notificación )
# 5: Batería llena
# 6: Cargando

# Estado inicial
state=4  # Estado inicial (Batería suficiente)

while true; do

    # Obtener el estado de la batería
    output="$(acpi -b | grep -v 'unavailable')"

    if [ -z "$output" ]; then
        echo "No se pudo obtener el estado de la batería."
        continue
    fi
    

    # Analizar salida de ACPI
    _battery_id="${output%%: *}"
    output="${output#*: }"
    status="${output%%, *}"
    output="${output#*, }"
    percentage="${output%%, *}"
    _est_time="${output#*, }"
    percentage="${percentage%\%}"

    # Tratamos "Not charging" como "Discharging"
    if [ "$status" = "Not charging" ]; then
        status="Discharging"
    fi

    # Máquina de estados
    prev_state=$state  # Almacenar el estado anterior
    
    # Cargo la batería
    if [ "$status" = "Charging" ]; then

        # Eliminar archivo de batería descargando
        [ -f "$DISCHARGING_FILE" ] && rm "$DISCHARGING_FILE"

        if [ "$percentage" -ge "$THRESHOLD_FULL" ]; then
            # Cambio de estado de Cargando a Batería llena
            [ -f "$CHARGING_FILE" ] && rm "$CHARGING_FILE"

            state=5  # Batería llena
        else           
            # Cambio de estado de Batería baja a Cargando
            [ -f "$LOW_FILE" ] && rm "$LOW_FILE"

            # Cambio de estado de Batería muy baja a Cargando
            [ -f "$VERY_LOW_FILE" ] && rm "$VERY_LOW_FILE"

            # Cambio de estado de Batería crítica a Cargando
            [ -f "$CRITICAL_FILE" ] && rm "$CRITICAL_FILE"

            state=6  # Cargando
        fi
    else  # Descargo la batería
        
        # Cambio de estado de Cargando a Batería suficiente o Batería baja o Batería muy baja o Batería crítica
        [ -f "$CHARGING_FILE" ] && rm "$CHARGING_FILE"
        
        if [ "$percentage" -le "$THRESHOLD_CRITICAL" ]; then
            # Cambio de estado de Batería muy baja a Batería crítica
            [ -f "$VERY_LOW_FILE" ] && rm "$VERY_LOW_FILE"

            # Verificar si no existe el archivo de batería descargando y enviar notificación
            if [ ! -f "$DISCHARGING_FILE" ]; then
                # Quitar "remaining" de la estimación de tiempo
                _est_time="${_est_time% remaining*}"
                send_notification "Descargando: ${percentage}% Tiempo restante: ${_est_time}" "$CRITICAL_BATTERY_ICON"
                touch "$DISCHARGING_FILE"
            fi
            
            state=1  # Batería crítica
        elif [ "$percentage" -le "$THRESHOLD_VERY_LOW" ]; then
            # Cambio de estado de Batería baja a Batería muy baja
            [ -f "$LOW_FILE" ] && rm "$LOW_FILE"

            # Verificar si no existe el archivo de batería descargando y enviar notificación
            if [ ! -f "$DISCHARGING_FILE" ]; then
                # Quitar "remaining" de la estimación de tiempo
                _est_time="${_est_time% remaining*}"
                send_notification "Descargando: ${percentage}% Tiempo restante: ${_est_time}" "$LOW_BATTERY_ICON"
                touch "$DISCHARGING_FILE"
            fi

            state=2  # Batería muy baja
        elif [ "$percentage" -le "$THRESHOLD_LOW" ]; then
            # Cambio de estado de Batería suficiente a Batería baja

            # Verificar si no existe el archivo de batería descargando y enviar notificación
            if [ ! -f "$DISCHARGING_FILE" ]; then
                # Quitar "remaining" de la estimación de tiempo
                _est_time="${_est_time% remaining*}"
                send_notification "Descargando: ${percentage}% Tiempo restante: ${_est_time}" "$LOW_BATTERY_ICON"
                touch "$DISCHARGING_FILE"
            fi

            state=3  # Batería baja
        else
            # Cambio de estado de Batería lleno a Batería suficiente
            [ -f "$FULL_FILE" ] && rm "$FULL_FILE"

            # Verificar si no existe el archivo de batería descargando y enviar notificación
            if [ ! -f "$DISCHARGING_FILE" ]; then
                # Quitar "remaining" de la estimación de tiempo
                _est_time="${_est_time% remaining*}"
                send_notification "Descargando: ${percentage}% Tiempo restante: ${_est_time}" "$FULL_BATTERY_ICON"
                touch "$DISCHARGING_FILE"
            fi

            state=4  # Batería suficiente
        fi
    fi

    # Detectar cambios de estado
    if [ "$state" -ne "$prev_state" ]; then
        
        # Obtener el brillo actual
        current_brightness=$(brightnessctl get)
        
        # Esperar un segundo para evitar notificaciones duplicadas
        sleep 1

        case $state in
            1)  # Batería crítica
                # Verificar si no existe el archivo de batería crítica
                if [ ! -f "$CRITICAL_FILE" ]; then
                  send_notification "Batería crítica: ${percentage}%" "$CRITICAL_BATTERY_ICON"

                  # Crear archivo de batería crítica
                  touch "$CRITICAL_FILE" 

                  # Suspender el sistema cuando el estado sea crítico
                  echo "Sistema se suspenderá por batería crítica"
                  systemctl suspend  
                fi
                
                ;;
            2)  # Batería muy baja
                # Verificar si no existe el archivo de batería muy baja 
                if [ ! -f "$VERY_LOW_FILE" ]; then
                  send_notification "Batería muy baja: ${percentage}%" "$LOW_BATTERY_ICON"

                  # Verificar si el brillo actual es mayor al brillo muy bajo, entonces disminuirlo
                  if [ "$current_brightness" -gt "$BRIGHTNESS_VERY_LOW" ]; then
                    brightnessctl set $BRIGHTNESS_VERY_LOW  # Disminuir el brillo de la pantalla
                  fi

                  # Crear archivo de batería muy baja
                  touch "$VERY_LOW_FILE" 
                fi
                ;;
            3)  # Batería baja
                # Verificar si no existe el archivo de batería baja 
                if [ ! -f "$LOW_FILE" ]; then
                  send_notification "Batería baja: ${percentage}%" "$LOW_BATTERY_ICON"
                  
                  # Verificar si el brillo actual es mayor al brillo bajo, entonces disminuirlo
                  if [ "$current_brightness" -gt "$BRIGHTNESS_LOW" ]; then
                    brightnessctl set $BRIGHTNESS_LOW  # Disminuir el brillo de la pantalla
                  fi

                  # Crear archivo de batería baja
                  touch "$LOW_FILE" 
                fi
                ;;
            5)  # Batería llena
                # Verificar si no existe el archivo de batería llena
                if [ ! -f "$FULL_FILE" ]; then
                  send_notification "Batería llena: ${percentage}%" "$FULL_BATTERY_ICON"
            
                  # Crear archivo de batería llena
                  touch "$FULL_FILE" 
                fi

                ;;
            6)  # Cargando
                send_notification "Cargando: ${percentage}%" "$CHARGING_ICON"

                # Verificar si el brillo actual es menor al brillo alto, entonces aumentarlo
                if [ "$current_brightness" -lt "$BRIGHTNESS_HIGH" ]; then
                  brightnessctl set $BRIGHTNESS_HIGH  # Aumentar el brillo de la pantalla
                fi
                # Crear archivo de carga
                touch "$CHARGING_FILE"
                ;;
        esac
    fi
  
    # Esperar un tiempo
    sleep $FREQUENCY
done



