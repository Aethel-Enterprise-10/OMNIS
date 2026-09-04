#!/usr/bin/env python3
import json, subprocess, sys, os
from flask import Flask, request, jsonify
from pathlib import Path

def slm_infer(prompt):
    # Replace with your actual FastSLM inference.
    return f"FastSLM: {prompt[:100]}"

BLOOM_REPAIR = Path.home() / "BLOOM/bloom_repair_engine.py"
SHOGUN_HEALTH = Path.home() / "SYSTEM_ORGANIZED/SCRIPTS/shogun_health_check.py"
AEGIS_VERIFY = Path.home() / "SYSTEM_ORGANIZED/SCRIPTS/aegis_engine.py"
HASH_CHAIN = Path.home() / "hash_chain.jsonl"

def run_script(p, args=None):
    cmd = ["python3", str(p)]
    if args: cmd.extend(args)
    try:
        r = subprocess.run(cmd, capture_output=True, text=True, timeout=60)
        return {"status": "ok", "output": r.stdout} if r.returncode==0 else {"status":"error","output":r.stderr}
    except: return {"status":"error","output":"timeout"}

def route_tool(name, params=None):
    mapping = {"system_repair": BLOOM_REPAIR, "health_check": SHOGUN_HEALTH, "audit": AEGIS_VERIFY}
    if name in mapping: return run_script(mapping[name])
    if name == "hash_chain":
        try:
            with open(HASH_CHAIN) as f: lines=f.readlines()
            return {"status":"ok","output":json.dumps([json.loads(l) for l in lines[-20:]], indent=2)}
        except Exception as e: return {"status":"error","output":str(e)}
    return {"status":"unknown","output":f"Tool '{name}' not mapped"}

app = Flask(__name__)

@app.after_request
def after_request(response):
    response.headers.add('Access-Control-Allow-Origin', '*')
    response.headers.add('Access-Control-Allow-Headers', 'Content-Type,Authorization')
    response.headers.add('Access-Control-Allow-Methods', 'GET,PUT,POST,DELETE,OPTIONS')
    return response

@app.route("/status")
def status(): return jsonify({"status":"online","model":"FastSLM-0.6M"})
@app.route("/tool", methods=["POST"])
def tool():
    data=request.json or {}
    name=data.get("tool_name")
    if not name: return jsonify({"error":"Missing tool_name"}),400
    return jsonify(route_tool(name,data.get("params",{})))
@app.route("/v1/chat/completions", methods=["POST"])
def chat():
    data=request.json or {}
    tools=data.get("tools",[])
    if tools:
        name=tools[0].get("function",{}).get("name")
        if name:
            r=route_tool(name)
            return jsonify({"choices":[{"message":{"role":"assistant","content":r.get("output","No output")}}]})
    prompt=data.get("messages",[{}])[-1].get("content","")
    return jsonify({"choices":[{"message":{"role":"assistant","content":slm_infer(prompt)}}]})
if __name__=="__main__": app.run(host="0.0.0.0", port=5003, debug=False)
