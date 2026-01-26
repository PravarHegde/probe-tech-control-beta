import Vue from 'vue'
import VueI18n from 'vue-i18n'

Vue.use(VueI18n)

const locale = (import.meta.env.VUE_APP_I18N_LOCALE as string) || 'en'

const i18n = new VueI18n({
    locale,
    fallbackLocale: (import.meta.env.VUE_APP_I18N_FALLBACK_LOCALE as string) || 'en',
    messages: {},
    warnHtmlInMessage: 'off',
})

export default i18n

const localesMap = import.meta.glob('../locales/*.json')

export async function setAndLoadLocale(lang: string) {
    const loadLocale = localesMap[`../locales/${lang}.json`]
    if (loadLocale) {
        // @ts-ignore
        const locales = await loadLocale()
        i18n.setLocaleMessage(lang, locales.default || locales)
        i18n.locale = lang
        return locales
    }
}
