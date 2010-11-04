echo "drop database puppy" | mysql -u root
echo "create database puppy" | mysql -u root
mysql -u root puppy < ddl/0001_create_user.sql 
mysql -u root puppy < ddl/0002_insert_account.sql 
