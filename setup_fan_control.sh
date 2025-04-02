#!/bin/bash

echo "Creating fan control script..."
sudo tee /usr/local/bin/fan_control.sh > /dev/null <<EOF
#!/bin/bash

PWM_PATH="/sys/class/hwmon/hwmon7/pwm1"
TEMP_PATH="/sys/class/thermal/thermal_zone0/temp"

while true; do
    TEMP=\$(cat \$TEMP_PATH)
    TEMP=\$((TEMP / 1000))  # Convert to °C

    if [ \$TEMP -ge 60 ]; then
        echo 255 | sudo tee \$PWM_PATH  # Full speed at 60°C
    elif [ \$TEMP -ge 50 ]; then
        echo 128 | sudo tee \$PWM_PATH  # Half speed at 50°C
    else
        echo 0 | sudo tee \$PWM_PATH  # Turn off below 50°C
    fi

    sleep 5  # Check every 5 seconds
done
EOF

echo "Making fan control script executable..."
sudo chmod +x /usr/local/bin/fan_control.sh

echo "Setting up rc.local..."
sudo tee /etc/rc.local > /dev/null <<EOF
#!/bin/bash
/usr/local/bin/fan_control.sh &
exit 0
EOF

sudo chmod +x /etc/rc.local

echo "Creating systemd service for rc.local..."
sudo tee /etc/systemd/system/rc-local.service > /dev/null <<EOF
[Unit]
Description=/etc/rc.local Compatibility
ConditionPathExists=/etc/rc.local
After=network.target

[Service]
Type=forking
ExecStart=/etc/rc.local
TimeoutSec=0
StandardOutput=tty
RemainAfterExit=yes
SysVStartPriority=99

[Install]
WantedBy=multi-user.target
EOF

echo "Enabling and starting rc.local service..."
sudo systemctl enable rc-local
sudo systemctl start rc-local

echo "Checking service status..."
sudo systemctl status rc-local --no-pager

echo "Fan control setup complete!"
