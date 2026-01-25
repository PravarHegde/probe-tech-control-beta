import Dashboard from '../pages/Dashboard.vue'
import Webcam from '../pages/Webcam.vue'
import Farm from '../pages/Farm.vue'
import Console from '../pages/Console.vue'
import Files from '../pages/Files.vue'
import History from '../pages/History.vue'
import Timelapse from '../pages/Timelapse.vue'
import Machine from '../pages/Machine.vue'
import AgentDashboard from '../pages/AgentDashboard.vue'
import Connectivity from '../pages/Connectivity.vue'
import Marketplace from '../pages/Marketplace.vue'
import Heightmap from '../pages/Heightmap.vue'
import Viewer from '../pages/Viewer.vue'
import { AsyncComponent, Component } from 'vue'

import {
    mdiMonitorDashboard,
    mdiWebcam,
    mdiConsoleLine,
    mdiGrid,
    mdiFileDocumentMultipleOutline,
    mdiVideo3d,
    mdiHistory,
    mdiTimelapse,
    mdiWrench,
    mdiRobot,
    mdiQrcodeScan,
    mdiShopping,
} from '@mdi/js'

const routes: AppRoute[] = [
    {
        name: 'dashboard',
        title: 'Dashboard',
        path: '/',
        icon: mdiMonitorDashboard,
        component: Dashboard,
        alwaysShow: true,
        showInNavi: true,
        position: 10,
    },
    {
        name: 'agent',
        title: 'AI Agent',
        path: '/agent',
        icon: mdiRobot,
        component: AgentDashboard,
        alwaysShow: true,
        showInNavi: true,
        position: 15,
    },
    {
        name: 'connectivity',
        title: 'Pro Connect',
        path: '/connect',
        icon: mdiQrcodeScan,
        component: Connectivity,
        alwaysShow: true,
        showInNavi: true,
        position: 16,
    },
    {
        name: 'marketplace',
        title: 'Pro Shop',
        path: '/marketplace',
        icon: mdiShopping,
        component: Marketplace,
        alwaysShow: true,
        showInNavi: true,
        position: 17,
    },
    {
        name: 'farm',
        title: 'Printers',
        path: '/allPrinters',
        component: Farm,
        alwaysShow: false,
        showInNavi: false,
    },
    {
        name: 'webcam',
        title: 'Webcam',
        path: '/cam',
        icon: mdiWebcam,
        component: Webcam,
        alwaysShow: true,
        showInNavi: true,
        position: 20,
        fullscreen: true,
    },
    {
        name: 'console',
        title: 'Console',
        path: '/console',
        icon: mdiConsoleLine,
        component: Console,
        alwaysShow: true,
        showInNavi: true,
        klipperIsConnected: true,
        position: 30,
    },
    {
        name: 'heightmap',
        title: 'Heightmap',
        path: '/heightmap',
        icon: mdiGrid,
        component: Heightmap,
        alwaysShow: false,
        showInNavi: true,
        klipperComponent: 'bed_mesh',
        position: 40,
    },
    {
        name: 'gcodefiles',
        title: 'G-Code Files',
        path: '/files',
        icon: mdiFileDocumentMultipleOutline,
        component: Files,
        alwaysShow: true,
        showInNavi: true,
        registeredDirectory: 'gcodes',
        position: 50,
        fullscreen: true,
    },
    {
        name: 'gcodeviewer',
        title: 'G-Code Viewer',
        path: '/viewer',
        icon: mdiVideo3d,
        component: Viewer,
        alwaysShow: true,
        showInNavi: true,
        position: 60,
        fullscreen: true,
    },
    {
        name: 'history',
        title: 'History',
        path: '/history',
        icon: mdiHistory,
        component: History,
        alwaysShow: true,
        showInNavi: true,
        moonrakerComponent: 'history',
        position: 70,
    },
    {
        name: 'timelapse',
        title: 'Timelapse',
        path: '/timelapse',
        icon: mdiTimelapse,
        component: Timelapse,
        alwaysShow: true,
        showInNavi: true,
        moonrakerComponent: 'timelapse',
        position: 80,
    },
    {
        name: 'machine',
        title: 'Machine',
        path: '/config',
        icon: mdiWrench,
        component: Machine,
        alwaysShow: true,
        showInNavi: true,
        position: 90,
    },
    {
        title: null,
        component: null,
        alwaysShow: false,
        showInNavi: false,
        path: '/settings/machine',
        redirect: '/config',
    },
]

export default routes

export interface AppRoute {
    name?: string
    title: string | null
    path: string
    redirect?: string
    icon?: string
    component: Component | AsyncComponent | null
    alwaysShow: boolean
    showInNavi: boolean
    registeredDirectory?: string
    moonrakerComponent?: string
    klipperComponent?: string
    klipperIsConnected?: boolean
    children?: AppRoute[]
    position?: number
    fullscreen?: boolean
}
