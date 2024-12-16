import os
import re
import sys
import subprocess

def get_video_devices():
    """
    Выполняет команду `v4l2-ctl --list-devices` и извлекает все /dev/videoN.
    """
    try:
        # Выполнение команды
        result = subprocess.run(['v4l2-ctl', '--list-devices'], capture_output=True, text=True, check=True)
        output = result.stdout

        # Регулярное выражение для поиска /dev/videoN
        video_devices = re.findall(r'/dev/video\d+', output)
        return video_devices
    except subprocess.CalledProcessError as e:
        print(f"Ошибка при выполнении команды: {e}")
        return []

def create_camera_files(video_devices, base_port):
    """
    Создаёт файлы в /etc/motion/cameras/ для каждого устройства.
    """
    camera_dir = '/etc/motion/cameras'
    os.makedirs(camera_dir, exist_ok=True)  # Создаём папку, если её нет

    for device in video_devices:
        # Извлекаем номер устройства
        device_number = int(re.search(r'\d+', device).group())
        port = base_port + device_number
        camera_name = f"Cam{device_number}"

        # Генерируем содержимое файла
        camera_config = (
            f"stream_port {port}\n"
            f"videodevice {device}\n"
            f"lightswitch_percent 10\n"
            f"lightswitch_frames 30\n"
            f"threshold 5000\n"
            f"camera_name {camera_name}\n"
        )

        # Путь к файлу
        file_path = os.path.join(camera_dir, f"{camera_name}")

        # Записываем содержимое в файл
        try:
            with open(file_path, 'w') as f:
                f.write(camera_config)
            print(f"Создан файл конфигурации: {file_path}")
        except PermissionError:
            print(f"Ошибка: недостаточно прав для записи в {file_path}")

if __name__ == "__main__":
    # Получаем аргументы из командной строки
    args = sys.argv
    if len(args) > 1:
        try:
            base_port = int(args[1])  # Если порт указан, парсим его
        except ValueError:
            print("Ошибка: порт должен быть числом.")
            sys.exit(1)
    else:
        base_port = 8080  # Базовый порт по умолчанию

    # Получаем список устройств
    video_devices = get_video_devices()
    if not video_devices:
        print("Устройства не найдены.")
        sys.exit(1)

    # Создаём файлы конфигурации
    create_camera_files(video_devices, base_port)
