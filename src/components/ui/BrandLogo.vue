<template>
    <div class="brand-logo">
        <img src="@/assets/logo.svg" alt="Probe Tech Logo" />
    </div>
</template>

<script lang="ts">
import Component from 'vue-class-component'
import { Mixins, Prop } from 'vue-property-decorator'
import BaseMixin from '../mixins/base'

@Component
export default class BrandLogo extends Mixins(BaseMixin) {
    @Prop({ required: false, default: '' })
    declare readonly color: string
}
</script>

<style scoped>
.brand-logo img {
    max-height: 100%;
    max-width: 100%;
}
</style>
