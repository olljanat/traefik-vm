$traefikUri="http://localhost:8080"
$entrypoints = Invoke-RestMethod -Uri "$traefikUri/api/entrypoints"
$routers | Where-Object {$_.entryPoints -eq "web"} | ConvertTo-Json
{
  "entryPoints": [
    "web"
  ],
  "middlewares": [
    "redirect-web-to-websecure@internal"
  ],
  "service": "noop@internal",
  "rule": "HostRegexp(`{host:.+}`)",
  "priority": 2147483646,
  "status": "enabled",
  "using": [
    "web"
  ],
  "name": "web-to-websecure@internal",
  "provider": "internal"
}

$routers | Where-Object {$_.entryPoints -eq "websecure"} | ConvertTo-Json
[
  {
    "entryPoints": [
      "websecure"
    ],
    "middlewares": [
      "secHeaders@file"
    ],
    "service": "bar",
    "rule": "Host(`bar.com`)",
    "status": "enabled",
    "using": [
      "websecure"
    ],
    "name": "bar@file",
    "provider": "file"
  },
  {
    "entryPoints": [
      "websecure"
    ],
    "middlewares": [
      "secHeaders@file"
    ],
    "service": "foo",
    "rule": "Host(`foo.com`)",
    "status": "enabled",
    "using": [
      "websecure"
    ],
    "name": "foo@file",
    "provider": "file"
  }
]

$routers = Invoke-RestMethod -Uri "$traefikUri/api/http/routers"
$services = Invoke-RestMethod -Uri "$traefikUri/api/http/services"
$middlewares = Invoke-RestMethod -Uri "$traefikUri/api/http/middlewares"

