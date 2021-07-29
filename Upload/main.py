import os
import boto3
import subprocess
import time
import sys

process2 = subprocess.Popen(["git", "init"], stdout=subprocess.PIPE)
output2 = process2.communicate()[0]
print(output2)
process2 = subprocess.Popen(["git", "lfs", "install"], stdout=subprocess.PIPE)
output2 = process2.communicate()[0]
print(output2)
process2 = subprocess.Popen(["git", "lfs", "track", "\"*.jpg\""], stdout=subprocess.PIPE)
output2 = process2.communicate()[0]
print(output2)
process2 = subprocess.Popen(["git", "remote", "add", "origin", sys.argv[1]], stdout=subprocess.PIPE)
output2 = process2.communicate()[0]
print(output2)
process2 = subprocess.Popen(["git", "pull", "origin", "master"], stdout=subprocess.PIPE)
output2 = process2.communicate()[0]
print(output2)
folder = './.git/lfs/objects'
s3_client = boto3.client('s3')
while(True):
    time.sleep(3)
    process2 = subprocess.Popen(["git", "pull", "origin3", "master"], stdout=subprocess.PIPE)
    output2 = process2.communicate()[0]
    print(output2)
    for item in os.walk(folder):
        if len(item[2]) != 0:
            path = str(item[0]) + '/' + str(item[2][0])
            print(path)
            s3_client.upload_file(path, sys.argv[2], str(item[2][0]))