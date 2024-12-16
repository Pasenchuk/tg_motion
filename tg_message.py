from telegram import Bot
import sys
import os

bot_token = ''
bot_user_name = ''
chat_id = ''

lan_ip = os.popen("hostname -I").read().strip()
wan_ip = os.popen("curl -s ipinfo.io/ip").read().strip()

global TOKEN
TOKEN = bot_token
bot = Bot(token=TOKEN)


camera_id = sys.argv[1]
cam = camera_id.split(':')[0]
port = camera_id.split(':')[1]
camera = f'{cam}\n\nhttp://{lan_ip}:{port}\n\nhttp://{wan_ip}:{port}'
event_type = sys.argv[2]

if event_type == 'event':
    bot.send_message(chat_id=chat_id,text = f"Обнаружено движение: камера {camera}")
if event_type == 'lost':
    bot.send_message(chat_id=chat_id,text = f"Камера {camera} отключена")
if event_type == 'found':
    bot.send_message(chat_id=chat_id,text = f"Камера {camera} подключена")
if event_type == 'photo':
    path = sys.argv[3]
    try:
        bot.send_photo(chat_id=chat_id,photo=open(path,'rb'), caption=camera,timeout=1000000)
        os.remove(path)
    except:
        os.remove(path)
        bot.send_message(chat_id=chat_id,text = f"Не получилось отправить фото {path} с {camera}")
if event_type == 'video':
    path = sys.argv[3]
    try:
        if os.stat(path).st_size > 0:
            bot.send_video(chat_id=chat_id,video=open(path,'rb'), supports_streaming=True,caption=camera,timeout=1000000)
        else:
            bot.send_message(chat_id=chat_id,text = f"Пустой файл {path} с {camera}")
        os.remove(path)
    except:
        os.remove(path)
        bot.send_message(chat_id=chat_id,text = f"Не получилось отправить видео {path} с {camera}")
