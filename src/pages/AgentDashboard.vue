<template>
    <div class="agent-dashboard">
        <v-row>
            <v-col cols="12" md="8">
                <v-card class="glass-panel mb-4">
                    <v-card-title class="headline primary--text">
                        <v-icon left color="primary">mdi-robot</v-icon>
                        AI Job Planner
                    </v-card-title>
                    <v-card-text>
                        <div class="chat-interface pa-4" style="height: 400px; overflow-y: auto; background: rgba(0,0,0,0.2); border-radius: 8px;">
                            <div class="d-flex mb-2">
                                <v-avatar size="32" color="primary" class="mr-2">AI</v-avatar>
                                <div class="glass-card pa-2 rounded-lg">
                                    Hello! I am your intelligent print agent. I can help you optimize your print settings, debug issues, or schedule jobs. How can I assist you today?
                                </div>
                            </div>
                        </div>
                        <v-text-field
                            placeholder="Ask me anything about your 3D printing tasks..."
                            outlined
                            dense
                            class="mt-4"
                            append-icon="mdi-send"
                        ></v-text-field>
                    </v-card-text>
                </v-card>
            </v-col>

            <v-col cols="12" md="4">
                <v-card class="glass-panel mb-4">
                    <v-card-title class="headline secondary--text">
                        <v-icon left color="secondary">mdi-heart-pulse</v-icon>
                        System Health
                    </v-card-title>
                    <v-card-text>
                        <v-list dense color="transparent">
                            <v-list-item>
                                <v-list-item-content>CPU Load</v-list-item-content>
                                <v-list-item-action>
                                    <v-progress-linear value="15" color="secondary" style="width: 100px"></v-progress-linear>
                                </v-list-item-action>
                            </v-list-item>
                             <v-list-item>
                                <v-list-item-content>RAM Usage</v-list-item-content>
                                <v-list-item-action>
                                    <v-progress-linear value="42" color="accent" style="width: 100px"></v-progress-linear>
                                </v-list-item-action>
                            </v-list-item>
                             <v-list-item>
                                <v-list-item-content>Network Latency</v-list-item-content>
                                <v-list-item-action class="success--text">
                                    12ms
                                </v-list-item-action>
                            </v-list-item>
                        </v-list>
                    </v-card-text>
                </v-card>

                <v-card class="glass-panel">
                    <v-card-title class="headline accent--text">
                        <v-icon left color="accent">mdi-flash</v-icon>
                        Optimization
                    </v-card-title>
                    <v-card-text>
                        <div class="text-center">
                            <v-icon size="64" color="grey darken-2">mdi-check-circle-outline</v-icon>
                            <div class="mt-2">System Running Optimally</div>
                             <v-btn text color="primary" class="mt-2">Run Diagnostics</v-btn>
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
export default class AgentDashboard extends Vue {}
</script>

<style scoped>
.glass-card {
    background: rgba(255, 255, 255, 0.1);
    backdrop-filter: blur(5px);
}
</style>
