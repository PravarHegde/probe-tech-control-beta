<template>
    <div class="marketplace-page">
        <v-row class="mb-4">
             <v-col cols="12">
                <v-card class="glass-panel pa-2">
                    <div class="d-flex align-center">
                         <v-icon size="32" color="accent" class="mr-3">mdi-shopping</v-icon>
                         <h2 class="headline mb-0">Part Marketplace</h2>
                         <v-spacer></v-spacer>
                         <v-text-field
                            placeholder="Search parts, upgrades, models..."
                            hide-details
                            dense
                            outlined
                            prepend-inner-icon="mdi-magnify"
                            style="max-width: 300px"
                         ></v-text-field>
                    </div>
                </v-card>
             </v-col>
        </v-row>

        <v-row>
            <v-col v-for="i in 6" :key="i" cols="12" sm="6" md="4" lg="3">
                <v-card class="glass-panel" hover>
                     <div class="d-flex align-center justify-center purple darken-4" style="height: 200px">
                        <v-icon size="64" color="white" style="opacity: 0.5">mdi-cog</v-icon>
                     </div>
                    <v-card-title class="subtitle-1">High-Flow Nozzle Kit</v-card-title>
                    <v-card-subtitle class="d-flex justify-space-between align-center">
                        <span>Reliability Upgrade</span>
                        <v-chip color="accent" x-small outlined>Premium</v-chip>
                    </v-card-subtitle>
                    <v-card-text>
                        <div class="body-2">
                            Optimized for high-speed printing. Compatible with your current setup.
                        </div>
                         <div class="mt-2 text-h6 accent--text">₹1,499</div>
                    </v-card-text>
                    <v-card-actions>
                        <v-btn text small color="primary">Details</v-btn>
                        <v-spacer></v-spacer>
                        <v-btn
                            color="secondary"
                            small
                            class="px-2"
                            href="https://probharath.com"
                            target="_blank"
                        >
                            <v-icon left small>mdi-cart-plus</v-icon>
                            Buy Now
                        </v-btn>
                    </v-card-actions>
                </v-card>
            </v-col>
        </v-row>

        <v-row class="mt-6">
            <v-col cols="12">
                 <v-card class="glass-panel mb-4">
                    <v-card-title class="headline primary--text">
                        <v-icon left color="primary">mdi-cube-scan</v-icon>
                        One-Click Print Models
                    </v-card-title>
                    <v-card-text>
                        <v-row>
                            <v-col v-for="j in 4" :key="`model-${j}`" cols="6" md="3">
                                 <div class="glass-card pa-2 rounded-lg text-center" style="cursor: pointer">
                                    <v-icon size="64" color="white" class="mb-2">mdi-cube-outline</v-icon>
                                    <div class="subtitle-2">Calibration Cube</div>
                                    <v-btn x-small color="success" class="mt-2" rounded>Print Now</v-btn>
                                 </div>
                            </v-col>
                        </v-row>
                    </v-card-text>
                </v-card>
            </v-col>
        </v-row>
    </div>
</template>

<script lang="ts">
import { Component, Vue } from 'vue-property-decorator'

@Component
export default class Marketplace extends Vue {}
</script>

<style scoped>
.glass-card {
     background: rgba(255, 255, 255, 0.1);
     backdrop-filter: blur(5px);
     transition: transform 0.2s;
}
.glass-card:hover {
    transform: translateY(-2px);
    background: rgba(255, 255, 255, 0.15);
}
</style>
