#!/bin/bash
echo -n "Starting Inbox import..."
mkdir out/
readpst -r -M -o out/ outlook.pst > /dev/null
echo " Done"

echo -n "Starting Archive import"
mkdir "out/Persoonlijke mappen/Archives"
find . -maxdepth 1 -type f -iname "archive*.pst" -print | while read archive
do
	echo -n "."
	readpst -r -M -o "out/Persoonlijke mappen/Archives/" $archive
done
echo " Done"

find "out/Persoonlijke mappen/Archives" -type d -name Agenda -or -name Logboek -or -name Taken -or -name Contactpersonen | while read line
do
	rm -rf "$line";
done

mkdir other/
mv out/Persoonlijke\ mappen/{Agenda,Logboek,Taken,Contactpersonen} other/ 2>&1 > /dev/null
mv out/Persoonlijke\ mappen/{Postvak\ IN,INBOX} 2>&1 >/dev/null
mv out/Persoonlijke\ mappen/{INBOX/*/,} 2>&1 >/dev/null
mv out/Persoonlijke\ mappen/{Concepten,Drafts} 2>&1 >/dev/null
mv out/Persoonlijke\ mappen/{Verzonden\ items,Sent} 2>&1 >/dev/null
mv out/Persoonlijke\ mappen/{Verwijderde\ items,Trash} 2>&1 >/dev/null
mv out/Persoonlijke\ mappen/{Notities,Notes} 2>&1 >/dev/null

find out/Persoonlijke\ mappen/ -type d -not -name 'Persoonlijke mappen' -not -regex '.*/\(cur\|new\|tmp\)' -print | while read line
do
	mkdir "$line"/{new,cur,tmp}
done

find out/Persoonlijke\ mappen/ -type f -not -wholename '*/cur/*' -print | while read line
do
	mv "$line" "$(dirname "$line")/cur/"
done

echo -n "Creating Thunderbird Addressbooks"
find other/Contactpersonen -type d -print | while read abook
do
	echo -n "."
	find "$abook" -maxdepth 1 -type f -print | while read contact
	do
		cat "$contact" | tee -a "other/$(basename "$abook").vcf" > /dev/null
	done
	echo -n "."

	curl -F _format=ldif -F _vcards=@"other/$(basename "$abook").vcf" labs.brotherli.ch/vcfconvert/ -o "other/$(basename "$abook").ldif" 2>&1 >/dev/null
	echo -n "."
done
echo " Done"

echo -n "Creating vCalendar file"
echo "BEGIN:VCALENDAR" | tee -a "other/Agenda.ics" > /dev/null
echo "VERSION:2.0" | tee -a "other/Agenda.ics" > /dev/null

find other/Agenda/ -type f -print | while read vevent
do
	echo -n "."
	cat "$vevent" | tee -a "other/Agenda.ics" > /dev/null
done

echo "END:VCALENDAR" | tee -a "other/Agenda.ics" > /dev/null
echo " Done"
