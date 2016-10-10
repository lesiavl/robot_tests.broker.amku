*** Settings ***
Library   Selenium2Library
Library   Selenium2Screenshots
Library   BuiltIn
Library   amku_service.py
Library   String

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
#${locator.complaint.click.result}        xpath=//tr[@class="list-tree-level-0 good-claim rowlink"]
#${locator.amku.tender.id.verific}           xpath=//td[@data-title=""]

${locator.amku.pending.accepted}            xpath=//button[@data-warning-button="#accepted-button"]
${locator.amku.accepted.satisfied}          xpath=//button[@data-warning-button="#satisfied-button"]
${locator.amku.accepted.declined}           xpath=//button[@data-warning-button="#declined-button"]
${locator.amku.accepted.stopped}            xpath=//button[@data-warning-button="#stopped-button"]
${locator.amku.pending.invalid}             xpath=//button[@data-warning-button="#invalid-button"]
${locator.amku.pending.mistaken}            xpath=//button[@data-warning-button="#mistaken-button"]

${locator.tender.number}        xpath=//button[text()="№ закупівлі"]
${locator.tender.search}        xpath=//*[@id="blocks"]/div/input
${locator.go.to.tender}         xpath=//a[@class="items-list--header"]/span
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
  Run Keyword If  '${username}' == 'amku_Viewer'  Login To AMKU cabinet  ${username}


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
#  Register Keyword To Run On Failure    Пошук скарги по ідентифікатору


Оновити сторінку з тендером
  [Arguments]  ${username}  ${tender_uaid}
  amku.Пошук скарги по ідентифікатору   ${tender_uaid}  ${username}
  Reload Page


Отримати текст із поля
  [Arguments]  ${field_name}
  Wait Until Page Contains Element  ${field_name}  ${global.timeout}   error=No Such Element On Page
  ${return_value}=  Get Text  ${field_name}
  [Return]  ${return_value}


Отримати інформацію із скарги
  [Arguments]  ${tender_uaid}  ${username}  ${complaintID}  ${field_name}  ${award_index}
  Switch Browser  ${username}
  amku.Пошук скарги по ідентифікатору    ${tender_uaid}     ${username}
  Wait Until Element Is Visible     xpath=//*[contains(text(), "${tender_uaid}")]     ${global.timeout}  error=No complaint
  Click Element                     xpath=//*[contains(text(), "${tender_uaid}")]
  Wait Until Element Is Visible     ${field_name}            ${global.timeout}   error=element is not visible
  ${return_value}=  Run Keyword     Отримати інформацію із поля
  [Return]  ${return_value}


Пошук тендера по ідентифікатору на порталі Prozorro
  [Arguments]  ${TENDER_UAID}  ${username}
  [Documentation]  Пошук тендера на порталі Prozorro
  Open Browser                  https://qa23.prozorro.gov.ua/tender/search/       browser=chrome       alias=prozorro
  Click Button                  ${locator.tender.number}
  Input Text                    ${locator.tender.search}            ${TENDER_UAID}
  Wait Until Page Contains      ${TENDER_UAID}                      ${timeout.onwait}   error=NO TENDER ON THIS PAGE
  Reload Page
  Sleep  3   #Without sleep can't find the tender
  Click Element                 xpath=//*[@href="/tender/${TENDER_UAID}/"]
  ${tender.id.verific}=         Get Text                            ${locator.get.tender.ID}
  Page Should Contain Element   ${tender.id.verific.split(' ')[0]}  ${TENDER_UAID}


################################################
#       Test Case Keywords
################################################

Перевести скаргу в статус 'pending --> accepted'
  [Arguments]  ${tender_uaid}  ${username}
  [Documentation]   Перехід скарги в статус ACCEPTED/DECLINED (ПРИЙНЯТО ДО РОЗГЛЯДУ)
 # amku.Пошук скарги по ідентифікатору   ${tender_uaid}     ${username}
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
  Wait Until Element Is Visible         xpath=//div[@class="modal-body"]                            ${global.timeout}       error= Pending ==> Mistaken
  Click Element                         xpath=//input[@name="checkbox"]//following-sibling::label
  Wait Until Element Is Enabled         xpath=//*[@id="mistaken-button"]/button[1]                  ${global.timeout}
  Click Element                         xpath=//*[@id="mistaken-button"]/button[1]
  Wait Until Element Is Visible         xpath//input[@name="Claim[statusTranslated]"]               ${global.timeout}       error= Status not visible
  Page Should Contain Element           xpath=//input[@value="Повернуто, як помилково направлене повідомлення"]         message=No Element Повернуто, як помилково направлене повідомлення


Handling statuses
  @{current_tags}=   Get Variable Value  @{TEST TAGS}
  ${expected_status}=  Set Variable    ${EMPTY}
  Set Variable If  'accept_tender_complaint' in     '@{current_tags[-1]}'    ${expected_status} == u'Прийнята до розгляду'
  Set Variable If  'decline_tender_complaint' in    '@{current_tags[-1]}'    ${expected_status} == u'Не задоволена'
  Set Variable If  'satisfy_tender_complaint' in    '@{current_tags[-1]}'    ${expected_status} == u'Задоволена'
  Set Variable If  'stop_tender_complaint'    in    '@{current_tags[-1]}'    ${expected_status} == u'Розгляд припинено'
  Set Variable If  'return_mistaken_tender_complaint' in '@{current_tags[-1]}'  ${expected_status} == u'Повернуто, як помилково направлену'
  Set Variable If  'invalidate_tender_complaint' in '@{current_tags[-1]}'  ${expected_status} == u'Залишено без розгляду'
  [Return]  ${expected_status}


Звірити відображення поля status скарги із поля для користувача
  [Arguments]  ${tender_uaid}  ${username}
  [Documentation]   Перевірка статусу скарги на сторінці тендера
  amku.Пошук тендера по ідентифікатору на порталі Prozorro  ${username}  ${TENDER_UAID}
  Click Element     ${locator.go.to.tender}
  Wait Until Element Contains           ${locator.get.tender.ID}  ${TENDER_UAID}  ${global.timeout}  error=NO TENDER ON THIS PAGE
  Execute Javascript  window.scrollTo(0, 1378)
  ${expected_status}=  Handling statuses
  ${actual_status}=  Get Text  xpath=//div[@class="marked"]
  ${actual_status}=  Convert To String  ${actual_status}
  Should Be Equal As Strings   ${actual_status}    ${expected_status}   message=${actual_status} and ${expected_status} do not match on Prozorro.Test Failed.
