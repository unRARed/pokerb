web: CABLE_URL=ws://0.0.0.0:9293/cable LITECABLE_BROADCAST_ADAPTER=any_cable bundle exec puma
rpc: LITECABLE_BROADCAST_ADAPTER=any_cable bundle exec anycable
ws: anycable-go --debug --host 0.0.0.0 --port 9293 --broadcast_adapter=http
