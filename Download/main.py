import subprocess
import sys

process2 = subprocess.Popen(["git", "init"], stdout=subprocess.PIPE)
output2 = process2.communicate()[0]
print(output2.decode("utf-8"))
process2 = subprocess.Popen(["git", "lfs", "install"], stdout=subprocess.PIPE)
output2 = process2.communicate()[0]
print(output2.decode("utf-8"))
process2 = subprocess.Popen(["git", "config", "http.sslCert", sys.argv[1]], stdout=subprocess.PIPE)
output2 = process2.communicate()[0]
print(output2.decode("utf-8"))
process2 = subprocess.Popen(["git", "config", "http.sslKey", sys.argv[2]], stdout=subprocess.PIPE)
output2 = process2.communicate()[0]
print(output2.decode("utf-8"))
process2 = subprocess.Popen(["git", "lfs", "track", "\"*.jpg\""], stdout=subprocess.PIPE)
output2 = process2.communicate()[0]
print(output2.decode("utf-8"))
process2 = subprocess.Popen(["git", "remote", "add", "origin", sys.argv[3]], stdout=subprocess.PIPE)
output2 = process2.communicate()[0]
print(output2.decode("utf-8"))
process2 = subprocess.Popen(["git", "config", "-f", ".lfsconfig", "lfs.url", sys.argv[4]], stdout=subprocess.PIPE)
output2 = process2.communicate()[0]
print(output2.decode("utf-8"))
while(true):
    process2 = subprocess.Popen(["git", "pull", "origin", "master"], stdout=subprocess.PIPE)
    output2 = process2.communicate()[0]
    print(output2.decode("utf-8"))