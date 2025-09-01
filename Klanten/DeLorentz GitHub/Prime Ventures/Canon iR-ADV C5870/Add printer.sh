#!/bin/bash

# Printergegevens
PRINTER_NAME="Canon_IRADV_C5870"
PRINTER_IP="10.10.10.200"
PPD_FILE="CNPZUIR5870CZU.ppd.gz"
PPD_PATH="/Library/Printers/PPDs/Contents/Resources/${PPD_FILE}"

# Controleren of het PPD-bestand bestaat
if [ ! -f "$PPD_PATH" ]; then
    echo "Canon PPD-bestand niet gevonden: $PPD_PATH"
    exit 1
fi

# Printer toevoegen via IPP
/usr/sbin/lpadmin -p "$PRINTER_NAME" \
        -E \
        -v "ipp://${PRINTER_IP}/ipp/print" \
        -P "$PPD_PATH" \
        -o printer-is-shared=false

# Optioneel: instellen als standaardprinter
/usr/bin/lpoptions -d "$PRINTER_NAME"

echo "Printer $PRINTER_NAME succesvol toegevoegd."
exit 0