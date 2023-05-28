*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library    RPA.Browser.Selenium    auto_close=${FALSE}
Library           RPA.HTTP
Library    RPA.Tables
Library           RPA.PDF
Library           RPA.Archive
Library           OperatingSystem

*** Variables ***
${main_url}            https://robotsparebinindustries.com/#/robot-order

${img_folder}     ${CURDIR}${/}image_files
${pdf_folder}     ${CURDIR}${/}pdf_files
${output_folder}  ${CURDIR}${/}output

${orders_file}    ${CURDIR}${/}orders.csv
${zip_file}       ${output_folder}${/}pdf_order_archive.zip
${csv_url}        https://robotsparebinindustries.com/orders.csv

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Clean directory
    Open the robot order website
    ${orders}=    Download CSV and get orders
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill form for one order           ${row}
        Wait Until Keyword Succeeds     10x     2s    Preview the robot
        Wait Until Keyword Succeeds     10x     2s    Submit order
        ${orderid}  ${img_filename}=    Take a screenshot of the robot
        ${pdf_filename}=                Store the receipt as a PDF file    ORDER_NUMBER=${order_id}
        Embed the robot screenshot to the receipt PDF file     IMG_FILE=${img_filename}    PDF_FILE=${pdf_filename}
        Go to order another robot
    END
    Create a ZIP file of the receipts
    Log Out And Close The Browser

*** Keywords ***
Open the robot order website
    Open Available Browser    ${main_url}    
Download CSV and get orders
    Download    url=${csv_url}         target_file=${orders_file}    overwrite=True
    ${table}=   Read table from CSV    path=${orders_file}
    [Return]    ${table}

Clean directory
    Remove Directory     ${img_folder}
    Remove Directory     ${pdf_folder}

    Create Directory    ${img_folder}
    Create Directory    ${pdf_folder}

Fill form for one order
    [Arguments]    ${order}
    Select From List By Value    head    ${order}[Head]
    Select Radio Button      body    ${order}[Body]
    Input Text    xpath:/html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${order}[Legs]
    Input Text    address    ${order}[Address]

Preview the robot
    Click Button                    preview
    Wait Until Element Is Visible   robot-preview-image

Submit order
    Click button                    order
    Page Should Contain Element     receipt

Close the annoying modal
    Wait And Click Button    css:button[class="btn btn-dark"]

Go to order another robot
    Click Button            order-another

Create a Zip File of the receipts
    Archive Folder With ZIP     ${pdf_folder}  ${zip_file}   recursive=True  include=*.pdf

Embed the robot screenshot to the receipt PDF file
    [Arguments]     ${IMG_FILE}     ${PDF_FILE}
    Open PDF        ${PDF_FILE}
    @{myfiles}=       Create List     ${IMG_FILE}:x=0,y=0
    Add Files To PDF    ${myfiles}    ${PDF_FILE}     ${True}
    Close PDF           ${PDF_FILE}

Log Out And Close The Browser
    Close Browser

Store the receipt as a PDF file
    [Arguments]        ${ORDER_NUMBER}
    Wait Until Element Is Visible   receipt
    ${order_receipt_html}=          Get Element Attribute   receipt  outerHTML
    Html To Pdf                     content=${order_receipt_html}   output_path=${pdf_folder}${/}${ORDER_NUMBER}.pdf
    [Return]    ${pdf_folder}${/}${ORDER_NUMBER}.pdf

Take a screenshot of the robot
    Wait Until Element Is Visible   robot-preview-image
    Wait Until Element Is Visible   xpath://html/body/div/div/div[1]/div/div[1]/div/div/p[1]
    ${orderid}=                     Get Text            //*[@id="receipt"]/p[1]
    Capture Element Screenshot      robot-preview-image   ${img_folder}${/}${orderid}.png
    [Return]    ${orderid}  ${img_folder}${/}${orderid}.png