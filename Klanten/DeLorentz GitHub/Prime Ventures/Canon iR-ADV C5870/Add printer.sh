#!/bin/bash

/usr/sbin/lpadmin -p canonc5870 \
  -D "Canon iR-ADV C5870" \
  -E \
  -v "ipp://10.10.10.200/ipp/print" \
  -P "/Library/Printers/PPDs/Contents/Resources/CNPZUIR5870CZU.ppd.gz" \
  -o printer-is-shared=false

/usr/bin/lpoptions -d canonc5870