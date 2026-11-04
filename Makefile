.PHONY: check

check:
	sh -n scripts/capture-dnscap.sh
	sh -n scripts/pcap-submit-to-oarc.sh
	sh -n scripts/setup-minio-alias.sh
	sh -n scripts/settings.example.sh
