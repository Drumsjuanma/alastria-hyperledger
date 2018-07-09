
cd alastria && sudo ./start.sh && mysql -u root -p < db/fabricexplorer.sql
cd ../caixabank/ && sudo ./start.sh && mysql -u root -p < db/fabricexplorer.sql
cd ../silk/ && sudo ./start.sh && mysql -u root -p < db/fabricexplorer.sql

