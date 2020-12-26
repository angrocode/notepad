
import re
import uuid
import base64
import hashlib
import secrets
from json import loads as jdict
from urllib.request import Request, build_opener, HTTPCookieProcessor
from urllib.parse import urlencode
from urllib.error import HTTPError, URLError
from http.cookiejar import CookieJar


class GetToken(object):
    verifier = base64.urlsafe_b64encode(secrets.token_bytes(32))
    m = hashlib.sha256()
    m.update(verifier)
    d = m.digest()
    challenge = base64.urlsafe_b64encode(d).decode().replace('=', '')
    stategen = uuid.uuid4()
    cookies = CookieJar()
    fields = dict()
    recode = str()

    def __init__(self, idapp, username, password):
        self.idapp = idapp
        self.username = username
        self.password = password

    @property
    def get(self):
        self.refresh()
        self.login_page()
        self.login()
        self.verification()
        self.character_select()
        self.character_page()
        if len(self.recode) == 0:
            self.character()
        self.token()

        if self.recode == 'json':
            return self.fields

    def refresh(self):
        ''' Step 0
        Send Refresh token
        '''

        print('If no refresh token leave the field empty and press the button enter.')
        token = str(input('Refresh token:'))
        if token == '': return

        self.fields['grant_type'] = 'refresh_token'
        self.fields['refresh_token'] = token
        self.fields['client_id'] = self.idapp

        request = Request(
            method='POST',
            headers={'Host': 'login.eveonline.com',
                     'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:76.0) Gecko/20100101 Firefox/76.0',
                     'Content-Type': 'application/x-www-form-urlencoded'
                     },
            url='https://login.eveonline.com/v2/oauth/token',
            data=urlencode(self.fields).encode()
        )

        self.fields = self.__pars(self.__send(request))

    def login_page(self):
        ''' Step 1
        Get fields login page
        Get cookies
        '''

        request = Request(
            method='GET',
            headers={'Host': 'login.eveonline.com',
                     'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:76.0) Gecko/20100101 Firefox/76.0'
                     },
            url='https://login.eveonline.com/account/logon'
        )

        self.fields = self.__pars(self.__send(request))

    def login(self):
        ''' Step 2
        Send login, password
        '''

        self.fields['UserName'] = self.username
        self.fields['Password'] = self.password

        request = Request(
            method='POST',
            headers={'Host': 'login.eveonline.com',
                     'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:76.0) Gecko/20100101 Firefox/76.0',
                     'Content-Type': 'application/x-www-form-urlencoded',
                     'Origin': 'https://login.eveonline.com',
                     'Referer': 'https://login.eveonline.com/account/logon'
                     },
            url='https://login.eveonline.com/account/logon',
            data=urlencode(self.fields).encode()
        )

        self.fields = self.__pars(self.__send(request))

    def verification(self):
        ''' Step 3
        Sending the code received by email
        '''

        verification_code = input('Please enter the verification code we just sent to your email address:')

        self.fields['Challenge'] = verification_code

        request = Request(
            method='POST',
            headers={'Host': 'login.eveonline.com',
                     'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:76.0) Gecko/20100101 Firefox/76.0',
                     'Content-Type': 'application/x-www-form-urlencoded',
                     'Origin': 'https://login.eveonline.com',
                     'Referer': 'https://login.eveonline.com/account/logon',
                     },
            url='https://login.eveonline.com/account/verifytwofactor',
            data=urlencode(self.fields).encode()
        )

        self.__send(request)

    def character_select(self):
        ''' Step 4
        Select character
        Get state
        Get token authorization
        '''

        url = {
            'response_type': 'code',
            'redirect_uri': 'https://login.eveonline.com',
            'client_id': self.idapp,
            'state': self.stategen,
            'code_challenge': self.challenge,
            'code_challenge_method': 'S256',
            'scope': 'publicData '
                     'esi-calendar.respond_calendar_events.v1 '
                     'esi-calendar.read_calendar_events.v1 '
                     'esi-location.read_location.v1 '
                     'esi-location.read_ship_type.v1 '
                     'esi-mail.organize_mail.v1 '
                     'esi-mail.read_mail.v1 '
                     'esi-mail.send_mail.v1 '
                     'esi-skills.read_skills.v1 '
                     'esi-skills.read_skillqueue.v1 '
                     'esi-wallet.read_character_wallet.v1 '
                     'esi-wallet.read_corporation_wallet.v1 '
                     'esi-search.search_structures.v1 '
                     'esi-clones.read_clones.v1 '
                     'esi-characters.read_contacts.v1 '
                     'esi-universe.read_structures.v1 '
                     'esi-bookmarks.read_character_bookmarks.v1 '
                     'esi-killmails.read_killmails.v1 '
                     'esi-corporations.read_corporation_membership.v1 '
                     'esi-assets.read_assets.v1 '
                     'esi-planets.manage_planets.v1 '
                     'esi-fleets.read_fleet.v1 '
                     'esi-fleets.write_fleet.v1 '
                     'esi-ui.open_window.v1 '
                     'esi-ui.write_waypoint.v1 '
                     'esi-characters.write_contacts.v1 '
                     'esi-fittings.read_fittings.v1 '
                     'esi-fittings.write_fittings.v1 '
                     'esi-markets.structure_markets.v1 '
                     'esi-corporations.read_structures.v1 '
                     'esi-characters.read_loyalty.v1 '
                     'esi-characters.read_opportunities.v1 '
                     'esi-characters.read_chat_channels.v1 '
                     'esi-characters.read_medals.v1 '
                     'esi-characters.read_standings.v1 '
                     'esi-characters.read_agents_research.v1 '
                     'esi-industry.read_character_jobs.v1 '
                     'esi-markets.read_character_orders.v1 '
                     'esi-characters.read_blueprints.v1 '
                     'esi-characters.read_corporation_roles.v1 '
                     'esi-location.read_online.v1 '
                     'esi-contracts.read_character_contracts.v1 '
                     'esi-clones.read_implants.v1 '
                     'esi-characters.read_fatigue.v1 '
                     'esi-killmails.read_corporation_killmails.v1 '
                     'esi-corporations.track_members.v1 '
                     'esi-wallet.read_corporation_wallets.v1 '
                     'esi-characters.read_notifications.v1 '
                     'esi-corporations.read_divisions.v1 '
                     'esi-corporations.read_contacts.v1 '
                     'esi-assets.read_corporation_assets.v1 '
                     'esi-corporations.read_titles.v1 '
                     'esi-corporations.read_blueprints.v1 '
                     'esi-bookmarks.read_corporation_bookmarks.v1 '
                     'esi-contracts.read_corporation_contracts.v1 '
                     'esi-corporations.read_standings.v1 '
                     'esi-corporations.read_starbases.v1 '
                     'esi-industry.read_corporation_jobs.v1 '
                     'esi-markets.read_corporation_orders.v1 '
                     'esi-corporations.read_container_logs.v1 '
                     'esi-industry.read_character_mining.v1 '
                     'esi-industry.read_corporation_mining.v1 '
                     'esi-planets.read_customs_offices.v1 '
                     'esi-corporations.read_facilities.v1 '
                     'esi-corporations.read_medals.v1 '
                     'esi-characters.read_titles.v1 '
                     'esi-alliances.read_contacts.v1 '
                     'esi-characters.read_fw_stats.v1 '
                     'esi-corporations.read_fw_stats.v1 '
                     'esi-characterstats.read.v1'
        }

        request = Request(
            method='GET',
            headers={'Host': 'login.eveonline.com',
                     'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:76.0) Gecko/20100101 Firefox/76.0',
                     'Content-Type': 'application/x-www-form-urlencoded'
                     },
            url='https://login.eveonline.com/v2/oauth/authorize?' + urlencode(url).replace('+', '%20')
        )

        response = self.__send(request)
        self.fields = self.__pars(response)

        start = response['web'].find('method="post"')
        end = response['web'].find('class="submit')
        characters = re.finditer(r'(?<=id="SelectedCharacterId").*?(?=src)', response['web'][start:end], flags=re.DOTALL)

        character_ids = dict()
        for number, character in enumerate(characters, start=1):
            string_list = character.group().split('\r\n')
            id = re.search(r'(?<=value=").*?(?=")', string_list[0])[0]
            print(number, string_list[2].strip(), 'ID:', id)
            character_ids[number] = id

        select = int(input('Character number:'))
        self.fields['SelectedCharacterId'] = character_ids[select]

    def character_page(self):
        ''' Step 5
        Sending selected character
        '''

        request = Request(
            method='POST',
            headers={'Host': 'login.eveonline.com',
                     'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:76.0) Gecko/20100101 Firefox/76.0'
                     },
            url='https://login.eveonline.com/v2/oauth/selectcharacter?' + 'state=' + self.fields['State'],
            data=urlencode(self.fields).encode()
        )

        self.fields = self.__pars(self.__send(request))

    def character(self):
        ''' Step 6
        Sending a confirmation
        '''

        self.fields['Accept'] = 'True'
        self.fields['action'] = 'Authorize'

        request = Request(
            method='POST',
            headers={'Host': 'login.eveonline.com',
                     'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:76.0) Gecko/20100101 Firefox/76.0',
                     'Referer': 'https://login.eveonline.com/v2/oauth/authorizeapp?' + 'state=' + self.fields['StateId']
                     },
            url='https://login.eveonline.com/v2/oauth/authorize',
            data=urlencode(self.fields).encode()
        )

        self.fields = self.__pars(self.__send(request))

    def token(self):
        ''' Step 7
        Get access and refresh token
        '''

        self.fields = dict()
        self.fields['grant_type'] = 'authorization_code'
        self.fields['code'] = self.recode
        self.fields['client_id'] = self.idapp
        self.fields['code_verifier'] = self.verifier

        request = Request(
            method='POST',
            headers={'Host': 'login.eveonline.com',
                     'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:76.0) Gecko/20100101 Firefox/76.0',
                     'Content-Type': 'application/x-www-form-urlencoded'
                     },
            url='https://login.eveonline.com/v2/oauth/token',
            data=urlencode(self.fields).encode()
        )

        self.fields = self.__pars(self.__send(request))

    def __pars(self, data):
        code = re.search(r'(?<=code=).*?(?=&)', data['url'])
        if code:
            self.recode = code[0]
            return

        if data['subtype'] == 'json':
            form = dict()
            self.recode = 'json'
            data = jdict(data['web'])
            form['expires_in'] = str(data['expires_in']) + ' sec'
            form['token_type'] = data['token_type']
            form['access_token'] = data['access_token']
            form['refresh_token'] = data['refresh_token']
            return form

        if data['subtype'] == 'html':
            form = dict()
            start = data['web'].find('method="post"')
            end = data['web'].find('class="submit')

            fields = re.finditer(r'(name\s*=\s*").*?(?=\s*\/>)', data['web'][start:end])
            for field in fields:
                name = re.search(r'(?<=name=").*?(?=")', field.group())
                value = re.search(r'(?<=value=").*?(?=")', field.group())

                form[name[0]] = value[0] if value else ''

            return form

    def __send(self, request):
        opener = build_opener(HTTPCookieProcessor(self.cookies))
        try:
            response = opener.open(request)
        except HTTPError as e:
            print('apitoken HTTPError: ' + str(e.code) + ': ' + e.reason)
            raise SystemExit
        except URLError:
            print('apitoken URLError')
            raise SystemExit

        web = response.read().decode('utf_8')
        url = response.geturl()
        subtype = response.info().get_content_subtype()

        # print('=================================')
        # print('status>>> ', response.getcode())
        # print('info>>> ', response.info())
        # print('url>>> ', url)
        # print('page>>> ', web)
        # print('cookies >>> ', self.cookies)
        # print('=================================')

        response.close()

        return {'web': web, 'subtype': subtype, 'url': url}


if __name__ == '__main__':
    from sys import argv

    '''
    Input:
    1. Developer appID https://developers.eveonline.com/applications
    2. Login client account
    3. Password client account

    At runtime:
    1. E-mail verification code
    2. Choosing a character name to get api key
    '''
    tokens = GetToken(argv[1], argv[2], argv[3]).get

    print('API tokens:')
    print('Expires:', tokens['expires_in'])
    print('Type:', tokens['token_type'])
    print('Access token:', tokens['access_token'])
    print('Refresh token:', tokens['refresh_token'])
