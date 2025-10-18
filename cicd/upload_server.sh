#!/bin/sh
usr = root
ip = 44.237.81.94
rsa = aws_rsa_123
echo "==upload_server.sh step==1"
rm -f server.tar
echo "==upload_server.sh step==2"
tar -czvf server.tar server
echo "==upload_server.sh step==3"
scp -i aws_rsa_123 ./server.tar root@44.237.81.94:/home/slgz_aws/
echo "==upload_server.sh step==4"
ssh -i aws_rsa_123 root@44.237.81.94 "rm -rf /home/slgz_aws/server_bak"
echo "==upload_server.sh step==5"
ssh -i aws_rsa_123 root@44.237.81.94 "mv /home/slgz_aws/server /home/slgz_aws/server_bak"
echo "==upload_server.sh step==6"
ssh -i aws_rsa_123 root@44.237.81.94 "cd /home/slgz_aws; tar -xzvf server.tar;"
echo "==upload_server.sh step==sucess"