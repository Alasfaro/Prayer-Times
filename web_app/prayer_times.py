import requests
from datetime import datetime, timedelta
from flask import Flask, render_template

app = Flask(__name__)

def get_prayer_times(lat, long):
    base_url = f"http://api.aladhan.com/v1/timingsByCity?city=Mississauga&country=Canada&method=2"
    response = requests.get(base_url)
    data = response.json()
    return data

@app.route('/')
def prayer_times_update():
    # Mississauga latitude and longitude
    lat = 43.5890
    long = -79.6441
    prayer_times_data = get_prayer_times(lat, long)

    timings = prayer_times_data['data']['timings']

    Fajr = timings['Fajr']
    Dhuhr = timings['Dhuhr']
    Asr = timings['Asr']
    Maghrib = timings['Maghrib']
    Isha = timings['Isha']
    midnight = get_midnight(Isha, Fajr)

    prayer_times_info = (
        f"Fajr: {convert_to_12hour(Fajr)}\n"
        f"Dhuhr: {convert_to_12hour(Dhuhr)}\n"
        f"Asr: {convert_to_12hour(Asr)}\n"
        f"Maghrib: {convert_to_12hour(Maghrib)}\n"
        f"Isha: {convert_to_12hour(Isha)}\n"
        f"Midnight: {midnight}\n"
    )

    return render_template('index.html', prayer_times_info=prayer_times_info)

def get_midnight(Isha, Fajr):
    isha_dt = datetime.strptime(Isha, '%H:%M')
    fajr_dt = datetime.strptime(Fajr, '%H:%M')
    diff = fajr_dt - isha_dt
    if diff.days < 0:
        diff += timedelta(days=1)
    midnight_dt = isha_dt + diff/2
    midnight = midnight_dt.strftime('%I:%M %p')
    return midnight

def convert_to_12hour(time):
    time_24 = datetime.strptime(time, '%H:%M')
    return time_24.strftime('%I:%M %p')


if __name__ == '__main__':
    app.run(debug=True)
