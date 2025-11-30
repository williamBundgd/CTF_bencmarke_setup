# This file generates new self signed certificates for the setup.
# To change the endpoints, change the O=... and CN=... to whatever you would like.
# Also change the domain name in the extra.ext file

rm cert*

openssl genrsa -out cert.key 2048
openssl req -new -key cert.key -subj '/C=DK/ST=Denmark/O=BenchMarker/CN=bench.test' -out cert.csr  # O={company_name}/CN={your_domain_name}
openssl x509 -signkey cert.key -in cert.csr -req -days 365 -out cert.crt

openssl genrsa -out certCA.key 2048
openssl req -x509 -sha256 -days 1825 -key certCA.key -subj '/C=DK/ST=Denmark/O=BenchMarker/CN=BenchMarker CA' -out certCA.crt  # O={company_name}/CN={company_name} CA
openssl x509 -req -CA certCA.crt -CAkey certCA.key -in cert.csr -out cert.crt -days 365 -CAcreateserial -extfile extra.ext

openssl x509 -text -noout -in cert.crt


openssl x509 -in cert.crt -out cert.pem -outform PEM
openssl x509 -in certCA.crt -out certCA.pem -outform PEM

cat certCA.pem >> cert.pem

# NOTE: If you are using the runner with the VM, then no need to install the certificates on you PC
#       but if you are using the runner directly in a docker container, run the following commands (on debian/ubuntu):
#       `sudo apt-get install -y ca-certificates`
#       `sudo cp certCA.crt /usr/local/share/ca-certificates`
#       `sudo update-ca-certificates --fresh`
#       And then restart you PC
