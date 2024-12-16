#!/bin/bash

# Проверка обязательных переменных
REQUIRED_VARS=("TELEGRAM_API_TOKEN" "TELEGRAM_BOT_ID" "TELEGRAM_CHANNEL_ID")
OPTIONAL_VAR="CAMERA_PORT"

# Проверка, что скрипт запущен от имени root
if [[ "$EUID" -ne 0 ]]; then
  echo "Скрипт должен быть запущен с правами root. Запустите его с помощью sudo."
  exit 1
fi

# Функция для вывода справки
print_help() {
  echo "Использование скрипта:"
  echo "  Перед запуском необходимо задать следующие переменные окружения:"
  echo "  Обязательные:"
  echo "    TELEGRAM_API_TOKEN   - API токен Telegram бота."
  echo "    TELEGRAM_BOT_ID      - ID Telegram бота."
  echo "    TELEGRAM_CHANNEL_ID  - ID Telegram канала."
  echo ""
  echo "  Необязательные:"
  echo "    CAMERA_PORT          - Порт для потокового видеосервера первой камеры, последующие получат инкремент на 1"
  echo ""
  echo "Пример запуска:"
  echo "  TELEGRAM_API_TOKEN=<токен> TELEGRAM_BOT_ID=<бот id> TELEGRAM_CHANNEL_ID=<канал id> CAMERA_PORT=8080 ./script.sh"
}

# Проверяем наличие всех обязательных переменных
for var in "${REQUIRED_VARS[@]}"; do
  if [ -z ${var+x} ]; then
    echo "Ошибка: Переменная $var не задана."
    print_help
    exit 1
  fi
done

# Проверяем необязательную переменную и выводим сообщение, если она не задана
if [ -z ${OPTIONAL_VAR+x} ]; then
  echo "Предупреждение: Переменная CAMERA_PORT не задана. Будет использовано значение 8080."
fi

# Создаём пользователя tg_motion, если он ещё не существует
if ! id "tg_motion" &>/dev/null; then
  echo "Создаём пользователя tg_motion..."
  useradd -m -s /bin/bash tg_motion
  if [ $? -eq 0 ]; then
    echo "Пользователь tg_motion успешно создан."
  else
    echo "Не удалось создать пользователя tg_motion."
    exit 1
  fi
else
  echo "Пользователь tg_motion уже существует."
fi

# Переходим в домашнюю директорию пользователя tg_motion
home_dir=$(eval echo ~tg_motion)
if [ -d "$home_dir" ]; then
  echo "Найдена домашнюю директория пользователя tg_motion: $home_dir"
else
  echo "Домашняя директория пользователя tg_motion не найдена."
  exit 1
fi
sudo usermod -aG video tg_motion

sudo apt-get install -y python3-pip
sudo apt-get install -y python3-venv
sudo apt-get install -y v4l-utils

sudo mkdir /var/log/supervisor
sudo mkdir /var/log/motion
sudo touch /var/log/motion/motion.log
sudo cmod 777 /var/log/motion/motion.log

mkdir .ssh
mkdir .motion

sudo apt-get install -y supervisor
sudo apt-get install -y motion

sudo cp supervisor/motion.conf /etc/supervisor/conf.d/motion.conf
echo environment=HOME=\"$home_dir\",TELEGRAM_API_TOKEN=\"$TELEGRAM_API_TOKEN\",TELEGRAM_BOT_ID=\"$TELEGRAM_BOT_ID\",TELEGRAM_CHANNEL_ID=\"$TELEGRAM_CHANNEL_ID\" >> /etc/supervisor/conf.d/motion.conf

sudo cp motion/motion.conf /etc/motion/motion.conf
sudo mkdir /etc/motion/cameras
py_sender=$home_dir/tg_message.py
sudo cp tg_message.py $py_sender
sudo sed -i "s|bot_token = '';|bot_token = \"$TELEGRAM_API_TOKEN\";|" "$py_sender"
sudo sed -i "s|bot_user_name = '';|bot_user_name = \"$TELEGRAM_BOT_ID\";|" "$py_sender"
sudo sed -i "s|chat_id = '';|chat_id = \"$TELEGRAM_CHANNEL_ID\";|" "$py_sender"

sudo chown tg_motion $home_dir/tg_message.py

sudo python3 camera_generator.py $CAMERA_PORT

cd $home_dir
python3 -m venv venv_tg
venv_tg/bin/pip3 install python-telegram-bot==13.15

sudo supervisorctl reread
sudo supervisorctl update
sudo supervisorctl start
py

v4l2-ctl --list-devices
