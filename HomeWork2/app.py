import requests
import json
import os

from datetime import date

from requests.exceptions import HTTPError

from config import Config

config = Config(os.path.join('.', 'config.yaml'))


def app(config):

    # Iterator to list of dates
    for pd in config['process_date']:

        try:
            # Get token
            url = config['url'] + '/' + 'auth'
            headers = {"content-type": "application/json"}
            data = {"username": config['username'], "password": config['password']}
            r = requests.post(url, headers=headers, data=json.dumps(data))
            token = r.json()['access_token']

            # Get data
            url = config['url'] + '/' + 'out_of_stock'
            headers = {"content-type": "application/json", "Authorization": "JWT " + token}
            process_date = {"date": pd}
            response = requests.get(url, headers=headers, data=json.dumps(process_date))
            response.raise_for_status()

            if response.status_code == 200:

                # Convert data to JSON
                all_data = response.json()

                # Create dir for process date if not exists
                os.makedirs(os.path.join(config['directory'], pd), exist_ok=True)

                with open(os.path.join(config['directory'], pd, 'data.json'), 'w') as json_file:
                    # Get only product ids
                    only_product_id_dict = [{key:value for key,value in d.items() if key != 'date'} for d in all_data]
                    json.dump(only_product_id_dict, json_file)

            else:

                print('Error code: ', response.status_code)

        except HTTPError:
            print('HTTPError!')


if __name__ == '__main__':
    app(config=config.get_config('robot-dreams-api'))
