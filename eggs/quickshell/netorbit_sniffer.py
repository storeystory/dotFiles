#!/usr/bin/env python3
import sys
import json
import time
import requests
from collections import OrderedDict
from scapy.all import sniff, IP

# Cache geo lookups to avoid hammering the API
geo_cache = OrderedDict()
MAX_CACHE = 500
PRIVATE_RANGES = [
    "10.", "172.16.", "172.17.", "172.18.", "172.19.", "172.20.",
    "172.21.", "172.22.", "172.23.", "172.24.", "172.25.", "172.26.",
    "172.27.", "172.28.", "172.29.", "172.30.", "172.31.", "192.168.",
    "127.", "0.", "169.254.", "224.", "255."
]

def is_private(ip):
    return any(ip.startswith(r) for r in PRIVATE_RANGES)

def geo_lookup(ip):
    if ip in geo_cache:
        return geo_cache[ip]
    try:
        r = requests.get(f"http://ip-api.com/json/{ip}?fields=country,lat,lon,city", timeout=3)
        data = r.json()
        if data.get("country"):
            result = {
                "country": data.get("country", "Unknown"),
                "city": data.get("city", ""),
                "lat": data.get("lat", 0),
                "lon": data.get("lon", 0)
            }
            if len(geo_cache) >= MAX_CACHE:
                geo_cache.popitem(last=False)
            geo_cache[ip] = result
            return result
    except:
        pass
    return None

def packet_handler(pkt):
    if IP not in pkt:
        return
    dst = pkt[IP].dst
    if is_private(dst):
        return
    geo = geo_lookup(dst)
    if not geo:
        return
    output = {
        "ip": dst,
        "country": geo["country"],
        "city": geo["city"],
        "lat": geo["lat"],
        "lon": geo["lon"],
        "size": len(pkt),
        "time": int(time.time())
    }
    print(json.dumps(output), flush=True)

MY_IP = "10.0.1.215"

def is_private(ip):
    if ip == MY_IP:
        return True
    return any(ip.startswith(r) for r in PRIVATE_RANGES)

# and change the sniff line to:
sniff(filter="ip", prn=packet_handler, store=False)