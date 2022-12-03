import { Inject, Injectable } from '@angular/core';
import { DOCUMENT } from '@angular/common';
import { AppearanceType, MainColorType } from '../../modules/setting/common/select-theme/theme.model';
import { Theme } from 'ng-zorro-antd/core/config';
import StorageUtil from '../../utils/storage/Storage';

@Injectable({
  providedIn: 'root',
})
export class ThemeService {
  module = {
    appearance: {
      id: 'appearance',
      path: '',
      injectDirection: 'prepend',
      storageKey: 'theme_appearance',
      default: 'light' as AppearanceType,
    },
    mainColor: {
      id: 'mainColor',
      path: '/assets/theme/',
      injectDirection: 'append',
      storageKey: 'theme_mainColor',
      default: 'default' as MainColorType,
    },
  };
  appearance: AppearanceType = StorageUtil.get(this.module.appearance.storageKey) || this.module.appearance.default;
  mainColor: MainColorType = StorageUtil.get(this.module.mainColor.storageKey) || this.module.mainColor.default;
  DESIGN_TOKEN: Theme = {
    primaryColor: getComputedStyle(this.document.documentElement)
      .getPropertyValue('--MAIN_THEME_COLOR')
      .replace(' ', ''),
  };

  constructor(@Inject(DOCUMENT) private document: Document) {}
  initTheme() {
    this.changeAppearance(this.appearance, true);
    this.changeColor(this.mainColor, true);
  }
  getEditorTheme() {
    //Default Theme: https://microsoft.github.io/monaco-editor/index.html
    //'vs', 'vs-dark' or 'hc-black'
    return this.appearance === 'dark' ? 'vs-dark' : 'vs';
  }
  changeEditorTheme() {
    if (window.monaco?.editor) {
      window.monaco?.editor.setTheme(this.getEditorTheme());
    }
  }
  changeAppearance(name: AppearanceType, firstLoad = false) {
    this.changeModule('appearance', name, firstLoad);
    this.changeEditorTheme();
  }

  changeColor(name: MainColorType, firstLoad = false) {
    this.changeModule('mainColor', name, firstLoad);
  }
  changeModule(mid: 'appearance' | 'mainColor', name: string, firstLoad) {
    if (!firstLoad && (!name || name === this[mid])) {
      return;
    }
    const module = this.module[mid];
    const href = `${module.path}${name}.css`;
    this.loadCss(href, name, module.injectDirection).then(() => {
      if (!firstLoad) {
        this.removeCss(this[mid]);
        //@ts-ignore
        this[mid] = name;
      }
      StorageUtil.set(module.storageKey, name);
    });
  }
  private removeCss(theme): void {
    const removedThemeStyle = document.getElementById(theme);
    if (removedThemeStyle) {
      document.head.removeChild(removedThemeStyle);
    }
  }
  private loadCss(href, id: string, injectDirection): Promise<Event> {
    return new Promise((resolve, reject) => {
      const dom = document.createElement('link');
      dom.rel = 'stylesheet';
      dom.href = href;
      dom.id = id;
      document.head[injectDirection](dom);
      dom.onload = resolve;
      dom.onerror = (e) => {
        console.log('theme change error:', e);
        reject();
      };
    });
  }
}
