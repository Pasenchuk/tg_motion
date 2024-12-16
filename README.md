Скрипт для быстрой установки системы видеонаблюдения на основе motion с уведомлениями через телеграм бот

Как установить:

```bash
export TELEGRAM_API_TOKEN="token"
export TELEGRAM_BOT_ID="@bot name"
export TELEGRAM_CHANNEL_ID='@channel name'
export CAMERA_PORT=<порт первой камеры, по умолчанию 8080, для второй и далее будет увеличиваться на 1 (8081, 8082 и так далее)>
sudo timedatectl set-timezone  <часовой пояс>
sudo apt-get update
sudo apt-get install git
git clone https://github.com/Pasenchuk/tg_motion.git
cd tg_motion/
sudo -E ./install_camera.sh 
```
