<template>
    <div class="connectivity-page">
        <v-row>
            <v-col cols="12" md="6">
                <v-card class="glass-panel mb-4">
                    <v-card-title class="headline primary--text">
                        <v-icon left color="primary">mdi-qrcode-scan</v-icon>
                        Easy Connect (Mobile)
                    </v-card-title>
                    <v-card-text class="text-center">
                        <div class="glass-card pa-4 d-inline-block rounded-lg mt-2">
                             <!-- Placeholder for QR Code -->
                            <v-icon size="150" color="white">mdi-qrcode</v-icon>
                        </div>
                        <div class="mt-4 subtitle-1">
                            Scan to connect instantly via Probe Tech App
                        </div>
                        <div class="caption grey--text">
                            Network: Local ({{ hostname }}.local)
                        </div>
                    </v-card-text>
                </v-card>

                <v-card class="glass-panel">
                    <v-card-title class="headline info--text">
                        <v-icon left color="info">mdi-radar</v-icon>
                        Nearby Printers
                    </v-card-title>
                    <v-card-text>
                        <v-list class="transparent-list" dense>
                            <v-list-item>
                                <v-list-item-icon>
                                    <v-icon color="success">mdi-check-network</v-icon>
                                </v-list-item-icon>
                                <v-list-item-content>
                                    <v-list-item-title>Ender 3 V2 (Living Room)</v-list-item-title>
                                    <v-list-item-subtitle>192.168.1.105 - Idle</v-list-item-subtitle>
                                </v-list-item-content>
                                <v-list-item-action>
                                    <v-btn icon small><v-icon>mdi-link</v-icon></v-btn>
                                </v-list-item-action>
                            </v-list-item>
                             <v-list-item>
                                <v-list-item-icon>
                                    <v-icon color="grey">mdi-wifi-off</v-icon>
                                </v-list-item-icon>
                                <v-list-item-content>
                                    <v-list-item-title>Voron 2.4 (Garage)</v-list-item-title>
                                    <v-list-item-subtitle>Offline</v-list-item-subtitle>
                                </v-list-item-content>
                            </v-list-item>
                        </v-list>
                        <v-btn block text color="info" class="mt-2">Scan for more</v-btn>
                    </v-card-text>
                </v-card>
            </v-col>

            <v-col cols="12" md="6">
                <v-card class="glass-panel fill-height">
                    <v-card-title class="headline secondary--text">
                        <v-icon left color="secondary">mdi-cloud-outline</v-icon>
                        Cloud Relay
                    </v-card-title>
                    <v-card-text>
                        <v-alert
                            border="left"
                            colored-border
                            type="success"
                            elevation="2"
                            class="glass-card"
                            color="secondary"
                        >
                            <strong>Status: Active</strong><br>
                            Your printer is accessible via the web worldwide.
                        </v-alert>

                        <div class="mt-6">
                            <h3 class="title mb-2">Connect Web Dashboard</h3>
                            <v-text-field
                                label="Claim Code"
                                value="PTC-8821-X99L"
                                readonly
                                outlined
                                append-icon="mdi-content-copy"
                            ></v-text-field>
                            <p class="body-2 grey--text">
                                Enter this code at <strong>connect.probetech.io</strong> to add this printer to your cloud account.
                            </p>
                        </div>

                         <div class="mt-6">
                            <h3 class="title mb-2">Agent Permissions</h3>
                             <v-switch label="Allow Remote Debugging" color="secondary" input-value="true"></v-switch>
                             <v-switch label="AI Job Optimization" color="secondary" input-value="true"></v-switch>
                             <v-switch label="Push Notifications" color="secondary" input-value="true"></v-switch>
                        </div>
                    </v-card-text>
                </v-card>
            </v-col>
        </v-row>
    </div>
</template>

<script lang="ts">
import { Component, Vue } from 'vue-property-decorator'

@Component
export default class Connectivity extends Vue {
     get hostname(): string {
        return this.$store.state.printer.hostname || 'printer'
    }
}
</script>

<style scoped>
.glass-card {
    background: rgba(255, 255, 255, 0.05);
    backdrop-filter: blur(5px);
}
.transparent-list {
    background: transparent !important;
}
</style>
