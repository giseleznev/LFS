# LFS
## Create
1. *Создать ACM сертификат для dns домена, к которому будет привязан LFS сервер (updater.frozy.io).   
2. В папке create в файле variables.tf указать нужные переменные(aws_region, bucket_name, bucket_name_for_certificate, dns_name, path_to_certificate(для пробных запусков готовый сертификат уже лежит в этой папке)). Для пробного запуска можно ничего не менять, должно работать с значениями по умолчанию.
3. Запусть команды terraform init, terraform apply
4. В конце напечатается domain_name. Добавить в google domains CNAME-record: 
dns домена (updater.frozy.io) CNAME domain_name 
на этом 


#### *ACM cert:
1. Sign in to the AWS Management Console and open the ACM console at https://console.aws.amazon.com/acm/home. If the introductory page appears, choose Get Started. Otherwise, choose Request a certificate.
2. On the Request a certificate page, type your domain name. For more information about typing domain names, see Requesting a public certificate.
3. To add more domain names to the ACM certificate, type other names as text boxes open beneath the name you just typed.
4. Choose Next.
5. Choose DNS validation and Next.
6. On the Add tags page, you can optionally tag your certificate with metadata. Choose Review when done.
7. On the Validation page, click the down-arrow next to your domain name. Указанную тут СNAME record добавить в google domains.

## Upload
здесь запустить бесконечный скрипт, который из указанного репозитория все git lfs файлы закачивает в указанное bucket_nam, для пробного запуска можно пользоваться репозиторием из примера, там 3 jpg картинки. Последний аргумент - bucket_name, такой, если в variables.tf он не был изменен.
```
python3 main.py  https://github.com/giseleznev/repforserver.git lfsserverbucketname
```

## Download
здесь запустить бесконечный скрипт, который из указанного репозитория, обращаясь за lfs файлами по указанному домену, все файлы cкачивает cюда (на вход подать пользовательский сертификат и приватный ключ, для пробных запусков уже лежат тут)
```
python3 main.py ./MyClient.pem ./MyClient.key  https://github.com/giseleznev/repforserver.git https://updater.frozy.io
```
