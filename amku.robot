*** Settings ***
Library   Selenium2Library
Library   Selenium2Screenshots
Library   BuiltIn
Library   amku_service.py
Library   String

#Test Timeout  5 min

*** Variables ***
${global.timeout}   30
${timeout.onwait}   300

${locator.AMKU.login.field}                    xpath=//input[@name="login"]
${locator.AMKU.password.field}              xpath=//input[@name="password"]
${locator.AMKU.submit.button}               xpath=//button[@type="submit"]

${provider_login}     jdvornyk@prozorro.org
${provider_password}  jdvornyk

${locator.new.complaints}                     xpath=(//*[@href="https://qa-claims-test.prozorro.gov.ua/backend/prozorro/claims/claimspending"])[2]
${locator.all.complaints}                       xpath=(//*[@href="https://qa-claims-test.prozorro.gov.ua/backend/prozorro/claims/claimspending"])[1]
${locator.amku.search.field}                xpath=//*[@id="Toolbar-listToolbar"]/div/div[2]/div/input

${locator.amku.pending.accepted}            xpath=//button[@data-warning-button="#accepted-button"]
${locator.amku.accepted.satisfied}          xpath=//button[@data-warning-button="#satisfied-button"]
${locator.amku.accepted.declined}           xpath=//button[@data-warning-button="#declined-button"]
${locator.amku.accepted.stopped}            xpath=//button[@data-warning-button="#stopped-button"]
${locator.amku.pending.invalid}             xpath=//button[@data-warning-button="#invalid-button"]
${locator.amku.pending.mistaken}            xpath=//button[@data-warning-button="#mistaken-button"]

${locator.tender.number}        xpath=//button[text()="№ закупівлі"]
${locator.tender.search}        xpath=//*[@id="blocks"]/div/input
${locator.go.to.tender}         xpath=//a[@class="items-list--header"]
${locator.get.tender.ID}        xpath=//div[@class="tender--head--inf"]


*** Keywords ***
###################################################
#               Service Keywords
###################################################

Підготувати дані для оголошення тендера
  [Arguments]  ${username}  ${tender_data}  ${role_name}
  [Return]  ${tender_data}


Підготувати клієнт для користувача
  [Arguments]  ${username}
  Open Browser          ${USERS.users['${username}'].homepage}   ${USERS.users['${username}'].browser}  alias=${username}
  Set Window Size       @{USERS.users['${username}'].size}
  Set Window Position   @{USERS.users['${username}'].position}
  Run Keyword If        '${username}' == 'amku_Viewer'  Login To AMKU cabinet  ${username}
  Open Browser          https://qa23.prozorro.gov.ua/tender/search/       browser=chrome       alias=prozorro


Login To AMKU cabinet
  [Arguments]  ${username}
  Wait Until Page Contains Element  ${locator.AMKU.login.field}  10
  Input Text      ${locator.AMKU.login.field}     ${USERS.users['${username}'].AMKU_login}
  Input Text      ${locator.AMKU.password.field}  ${USERS.users['${username}'].AMKU_password}
  Click Element   ${locator.AMKU.submit.button}


Пошук тендера по ідентифікатору
  [Arguments]  ${username}  ${tender_uaid}
  Log To Console   Not using this keyword


Пошук скарги по ідентифікатору
  [Arguments]  ${tender_uaid}  ${username}
  [Documentation]   Пошук скарги в кабінеті АМКУ
  Log Many   @{TEST TAGS}
  Switch Browser              ${username}
  Input Text                        ${locator.amku.search.field}                    ${tender_uaid}
  Wait Until Element Is Visible     xpath=//*[contains(text(), "${tender_uaid}")]   30     error=No complaint
  Click Element                     xpath=//tr[@class="list-tree-level-0 good-claim rowlink"]              #xpath=//*[contains(text(), "${tender_uaid}")]
  Wait Until Element Is Visible     id=Form-field-Claim-complaint_complaintID   ${global.timeout}  error=No complaint


Пошук тендера по ідентифікатору на порталі Prozorro
  [Arguments]  ${TENDER_UAID}  ${username}
  [Documentation]  Пошук тендера на порталі Prozorro
  Switch Browser                    prozorro
  Click Element                     ${locator.tender.number}
  Input Text                        ${locator.tender.search}            ${TENDER_UAID}
  Sleep  5                          #Without sleep can't find the tender
  Wait Until Element Is Visible     xpath=//*[@href="/tender/${TENDER_UAID}/"]   30  error=NO TENDER ON THIS PAGE
  Click Element                     xpath=//*[@href="/tender/${TENDER_UAID}/"]
  ${tender.id.verific} =            Get Text                            ${locator.get.tender.ID}
  ${tender.id.verific} =            ${tender.id.verific.split(' ')}
  Page Should Contain Element       ${tender.id.verific[0]}     ${TENDER_UAID}


Оновити сторінку з тендером
  [Arguments]  ${username}  ${tender_uaid}
  amku.Пошук скарги по ідентифікатору   ${tender_uaid}  ${username}
  Reload Page


Отримати статус із поля
  [Timeout]  300 seconds
  [Arguments]  ${username}  ${tender_uaid}  ${tender_data}  ${field_name}
  ${complaints}=  Get Variable Value   ${USERS.users['${username}'].tender_data.data.complaints}
#  ${complaint_indecx}=   get_complaint_index_by_id   ${tender_data}
  ${field_value}=       Get Variable Value    ${complaints[0]['${field_name}']}
  [Return]  ${field_value}


Отримати інформацію із status
  [Arguments]        ${field_name}
  ${return_value} =  Get Text     xpath=//div[@class="marked"]
  ${return_value} =  Convert To String          ${return_value}
  [Return]  ${return_value}


Setting status due to tag
  [Documentation]  Використовується для порівняння статусу скарги згідно поточного тегу в тесті
  @{current_tags} =   Get Variables  @{TEST TAGS}
  ${expected_status}=  Set Variable If  'accept_tender_complaint'  in  '@{current_tags[-1]}'   u'Прийнята до розгляду'
  ${expected_status}=  Set Variable If  'decline_tender_complaint' in  '@{current_tags[-1]}'   u'Не задоволена'
  ${expected_status}=  Set Variable If  'satisfy_tender_complaint' in  '@{current_tags[-1]}'   u'Задоволена'
  ${expected_status}=  Set Variable If  'stop_tender_complaint'    in  '@{current_tags[-1]}'   u'Розгляд припинено'
  ${expected_status}=  Set Variable If  'return_mistaken_tender_complaint'  in  '@{current_tags[-1]}'   u'Повернуто, як помилково направлену'
  ${expected_status}=  Set Variable If  'invalidate_tender_complaint'       in  '@{current_tags[-1]}'   u'Залишено без розгляду'
  [Return]  ${expected_status}


Handling statuses
  [Documentation]  Використовується для порівняння статусу скарги згідно complaint_data
  ${expected_status}=  Setting status due to tag
  ${return_value}=  Set Variable If  ${expected_status} == u'Прийнята до розгляду'   'accepted'
  ${return_value}=  Set Variable If  ${expected_status} == u'Не задоволена'          'declined'
  ${return_value}=  Set Variable If  ${expected_status} == u'Задоволена'             'satisfied'
  ${return_value}=  Set Variable If  ${expected_status} == u'Розгляд припинено'      'stopped'
  ${return_value}=  Set Variable If  ${expected_status} == u'Повернуто, як помилково направлену'  'mistaken'
  ${return_value}=  Set Variable If  ${expected_status} == u'Залишено без розгляду'               'invalid'
  [Return]  ${return_value}


Отримати інформацію із скарги
  [Arguments]  ${tender_uaid}  ${username}  ${tender_data}  ${complaintID}  ${field_name}  ${award_index}=${None}
  [Documentation]   Перевірка статусу скарги на сторінці тендера
  amku.Пошук тендера по ідентифікатору на порталі Prozorro      ${username}     ${TENDER_UAID}
  Reload Page
  Run Keyword If Test Failed    Пошук тендера по ідентифікатору на порталі Prozorro   ${username}     ${TENDER_UAID}
  Execute Javascript  window.scrollTo(0, 1378)
  ${expected_status} =  Setting status due to tag
  ${actual_status} =    Отримати інформацію із status   ${field_name}
  Should Be Equal As Strings   ${actual_status}         ${expected_status}      message=${actual_status} and ${expected_status} do not match on Prozorro.
  ${return_value} =     Handling statuses
  [Return]  ${return_value}


################################################
#       Test Case Keywords
################################################

Перевести скаргу в статус 'pending --> accepted'
  [Arguments]  ${tender_uaid}  ${username}
  [Documentation]   Перехід скарги в статус ACCEPTED/DECLINED (ПРИЙНЯТО ДО РОЗГЛЯДУ)
  Execute Javascript                    window.scrollTo(0, 264)
  Click Element                         ${locator.amku.pending.accepted}
  Wait Until Element Is Visible         xpath=//div[@class="modal-body"]                ${global.timeout}
  Element Text Should Be                id=warning-title                                СКАРГА ПРИЙНЯТА ДО РОЗГЛЯДУ
  Click Element                         xpath=//input[@name="checkbox"]//following-sibling::label
  Wait Until Element Is Enabled         xpath=//*[@id="accepted-button"]/button[1]      ${global.timeout}       error= Pending ==> Accepted
  Click Element                         xpath=//*[@id="accepted-button"]/button[1]
  Wait Until Element Is Visible         xpath=//input[@name="Claim[statusTranslated]"]  ${global.timeout}       error= Status not visible
  Page Should Contain Element           xpath=//input[@value="Прийнято до розгляду"]    message=No Element Прийнято до розгляду


Перевести скаргу в статус 'accepted --> declined'
  [Arguments]  ${username}
  [Documentation]   Перехід скарги в статус ACCEPTED/DECLINED (ЗАЛИШИТИ БЕЗ ЗАДОВОЛЕННЯ)
  Switch Browser    ${username}
  Execute Javascript                    window.scrollTo(0, 264)
  Wait Until Element Is Visible         ${locator.amku.accepted.declined}                   ${global.timeout}
  Click Element                         ${locator.amku.accepted.declined}
  Wait Until Element Is Visible         xpath=//div[@class="modal-body"]                    ${global.timeout}       error= Accepted => Declined
  Element Text Should Be                id=warning-title                                    СКАРГА ВІДХИЛЕНА
  Click Element                         xpath=//input[@name="checkbox"]//following-sibling::label
  Wait Until Element Is Enabled         xpath=//*[@id="declined-button"]/button[1]          ${global.timeout}       error= Status not visible
  Click Element                         xpath=//*[@id="declined-button"]/button[1]
  Wait Until Element Is Visible         xpath=//input[@name="Claim[statusTranslated]"]
  Page Should Contain Element           xpath=//input[@value="Не задоволено"]               message=No Element Не задоволено


Перевести скаргу в статус 'accepted --> satisfied'
  [Arguments]  ${username}
  [Documentation]   Перехід скарги в статус ACCEPTED/SATISFIED (ЗАДОВОЛЬНИТИ)
  Switch Browser    ${username}
  Execute Javascript                    window.scrollTo(0, 264)
  Wait Until Element Is Visible         ${locator.amku.accepted.satisfied}                  ${global.timeout}
  Click Element                         ${locator.amku.accepted.satisfied}
  Wait Until Element Is Visible         xpath=//div[@class="modal-body"]                    ${global.timeout}           error= Accepted ==> Satisfied
  Element Text Should Be                id=warning-title                                    СКАРГА ЗАДОВОЛЕНА
  Click Element                         xpath=//input[@name="checkbox"]//following-sibling::label
  Wait Until Element Is Enabled         xpath=//*[@id="satisfied-button"]/button[1]         ${global.timeout}
  Click Element                         xpath=//*[@id="satisfied-button"]/button[1]
  Wait Until Element Is Visible         xpath=//input[@name="Claim[statusTranslated]"]      ${global.timeout}           error= Status not visible
  Page Should Contain Element           xpath=//input[@value="Задоволено"]                  message=No Element Задоволено


Перевести скаргу в статус 'accepted --> stopped'
  [Arguments]  ${username}
  [Documentation]   Перехід скарги в статус STOPPED (ПРИПИНИТИ РОЗГЛЯД)
  Switch Browser    ${username}
  Execute Javascript                    window.scrollTo(0, 264)
  Wait Until Element Is Visible         ${locator.amku.accepted.stopped}                        ${global.timeout}
  Click Element                         ${locator.amku.accepted.stopped}
  Wait Until Element Is Visible         xpath=//div[@class="modal-body"]                        ${global.timeout}       error= Accepted ==> Stopped
  Element Text Should Be                id=warning-title                                        РОЗГЛЯД СКАРГИ ЗУПИНЕНО
  Click Element                         xpath=//input[@name="checkbox"]//following-sibling::label
  Wait Until Element Is Enabled         xpath=//*[@id="stopped-button"]/button[1]               ${global.timeout}
  Click Element                         xpath=//*[@id="stopped-button"]/button[1]
  Wait Until Element Is Visible         xpath=//input[@name="Claim[statusTranslated]"]          ${global.timeout}       error= Status not visible
  Page Should Contain Element           xpath=//input[@value="Розгляд зупинено"]                message=No Element Розгляд зупинено


Перевести скаргу в статус 'pending --> invalid'
  [Arguments]  ${tender_uaid}  ${username}
  [Documentation]   Перехід скарги в статус INVALID (ЗАЛИШИТИ БЕЗ РОЗГЛЯДУ)
  Switch Browser    ${username}
  amku.Пошук скарги по ідентифікатору   ${tender_uaid}   ${username}
  Execute Javascript                    window.scrollTo(0, 264)
  Click Element                         ${locator.amku.pending.invalid}
  Wait Until Element Is Visible         xpath=//div[@class="modal-body"]                         ${global.timeout}
  Click Element                         xpath=//input[@name="checkbox"]//following-sibling::label
  Element Text Should Be                id=warning-title                                        СКАРГА ЗАЛИШЕНА БЕЗ РОЗГЛЯДУ
  Wait Until Element Is Visible         xpath=//div[@class="modal-body"]                        ${global.timeout}       error= Pending ==> Invalid
  Click Element                         xpath=//input[@name="checkbox"]//following-sibling::label
  Wait Until Element Is Enabled         xpath=//*[@id="invalid-button"]/button[1]               ${global.timeout}
  Click Element                         xpath=//*[@id="invalid-button"]/button[1]
  Wait Until Element Is Visible         xpath=//input[@name="Claim[statusTranslated]"]          ${global.timeout}       error= Status not visible
  Page Should Contain Element           xpath=//input[@value=" Не прийнято до розгляду"]        message=No Element  Не прийнято до розгляду


Перевести скаргу в статус 'pending --> mistaken'
  [Arguments]  ${tender_uaid}   ${username}
  [Documentation]   Перехід скарги в статус MISTAKEN (ПОВЕРНУТИ ЯК ПОМИЛКОВО НАПРАВЛЕНЕ ПОВІДОМЛЕННЯ)
  Switch Browser    ${username}
  amku.Пошук скарги по ідентифікатору   ${tender_uaid}   ${username}
  Execute Javascript                    window.scrollTo(0, 264)
  Click Element                         ${locator.amku.pending.mistaken}
  Wait Until Element Is Visible         xpath=//div[@class="modal-body"]                            ${global.timeout}
  Click Element                         xpath=//input[@name="checkbox"]//following-sibling::label
  Element Text Should Be                id=warning-title                                            ПОВЕРНУТИ, ЯК ПОМИЛКОВО НАПРАВЛЕНЕ ПОВІДОМЛЕННЯ
  Wait Until Element Is Visible         xpath=//div[@class="modal-body"]                            ${global.timeout}   error= Pending ==> Mistaken
  Click Element                         xpath=//input[@name="checkbox"]//following-sibling::label
  Wait Until Element Is Enabled         xpath=//*[@id="mistaken-button"]/button[1]                  ${global.timeout}
  Click Element                         xpath=//*[@id="mistaken-button"]/button[1]
  Wait Until Element Is Visible         xpath//input[@name="Claim[statusTranslated]"]               ${global.timeout}   error= Status not visible
  Page Should Contain Element           xpath=//input[@value="Повернуто, як помилково направлене повідомлення"]         message=No Element Повернуто, як помилково направлене повідомлення

