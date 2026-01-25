<template>
    <div>
        <!-- NUCLEAR OPTION: Raw HTML Div instead of Vuetify Component -->
        <div
            class="custom-sidebar-item d-flex align-center px-4"
            :class="itemClass"
            @click="handleNavigation"
            v-bind="$attrs"
            role="button"
            tabindex="0">
            
            <div class="my-3 mr-3 menu-item-icon">
                <v-icon>{{ icon }}</v-icon>
            </div>
            
            <div class="menu-item-content">
                <div class="menu-item-title text-truncate">
                    {{ title }}
                </div>
            </div>
        </div>
        <v-divider v-if="borderBottom" class="my-1" />
    </div>
</template>

<script lang="ts">
import Component from 'vue-class-component'
import { Mixins, Prop } from 'vue-property-decorator'
import BaseMixin from '@/components/mixins/base'
import { NaviPoint } from '@/components/mixins/navigation'

@Component
export default class SidebarItem extends Mixins(BaseMixin) {
    @Prop({ type: Object, required: true }) item!: NaviPoint

    get navigationStyle() {
        return this.$store.state.gui.uiSettings.navigationStyle
    }

    get icon() {
        return this.item.icon
    }

    get title() {
        return this.item.title
    }

    get to() {
        return this.item.to ?? undefined
    }

    get href() {
        return this.item.href ?? undefined
    }

    get target() {
        return this.item.target ?? undefined
    }

    get borderBottom() {
        return this.item.to === '/allPrinters'
    }

    get isActive(): boolean {
        if (this.item.target === '_blank' || !this.item.to) return false

        return this.$route.path === this.item.to
    }

    get itemClass() {
        return {
            'small-list-item': true,
            'active-nav-item': this.isActive,
        }
    }
    
    handleNavigation() {
        if (this.to) {
            if (this.$route.path !== this.to) {
                this.$router.push(this.to).catch(err => {
                    // Ignore navigation duplicated errors
                    if (err.name !== 'NavigationDuplicated') console.error(err)
                });
            }
        } else if (this.href) {
            if (this.target === '_blank') {
                window.open(this.href, '_blank');
            } else {
                window.location.href = this.href;
            }
        }
    }
}
</script>

<style scoped>
.small-list-item {
    height: var(--sidebar-menu-item-height);
}

.active-nav-item {
    border-right: 4px solid var(--v-primary-base);
}

.menu-item-icon {
    opacity: 0.85;
}

.menu-item-title {
    line-height: 30px;
    font-size: 14px;
    font-weight: 600;
    text-transform: uppercase;
    opacity: 0.85;
}

/* Custom Item Styles */
.custom-sidebar-item {
    cursor: pointer !important;
    pointer-events: auto !important;
    z-index: 10000 !important;
    transition: background-color 0.2s;
    user-select: none;
    position: relative;
    width: 100%;
}

.custom-sidebar-item:hover {
    background-color: rgba(255, 255, 255, 0.1);
}

.custom-sidebar-item:active {
    background-color: rgba(255, 255, 255, 0.2);
}
</style>
