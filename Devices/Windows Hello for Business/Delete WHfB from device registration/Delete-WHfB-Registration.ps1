# PS-script in Intune needs to be run in the User context
certutil /deletehellocontainer
shutdown /r /f /t 900 /c "Uw computer dient binnen 15 minuten opnieuw opgestart te worden."