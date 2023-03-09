import { Component, Input, OnInit, OnChanges, SimpleChanges, ViewChild, Output, EventEmitter } from '@angular/core';
import { Router } from '@angular/router';
import { EoSchemaFormComponent } from 'pc/browser/src/app/shared/components/schema-form/schema-form.component';
import { FeatureInfo } from 'pc/browser/src/app/shared/models/extension-manager';
import { ExtensionService } from 'pc/browser/src/app/shared/services/extensions/extension.service';
import { ApiService } from 'pc/browser/src/app/shared/services/storage/api.service';
import { Group } from 'pc/browser/src/app/shared/services/storage/db/models';
import { JSONParse } from 'pc/browser/src/app/utils/index.utils';

export const noAuth = {
  name: 'none',
  label: 'No Auth'
};

export const inheritAuth = {
  name: 'inherited',
  label: 'Inherit auth from parent'
};

export type AuthInfo = {
  authType: string;
  authInfo: Record<string, any>;
};

@Component({
  selector: 'authorization-extension-form',
  template: `
    <form nz-form nzLayout="vertical">
      <nz-form-item>
        <nz-form-label nzFor="authType" i18n>Type</nz-form-label>
        <nz-form-control>
          <eo-ng-radio-group name="authType" id="authType" [(ngModel)]="model.authType" (ngModelChange)="handleAuthTypeChange($event)">
            <label *ngFor="let item of authTypeList" eo-ng-radio [nzValue]="item.name">
              {{ item.label }}
            </label>
          </eo-ng-radio-group>
        </nz-form-control>
      </nz-form-item>
    </form>
    <nz-divider></nz-divider>
    <div class="my-[24px]">
      <ng-container *ngIf="inheritAuth.name === model.authType && parentGroup.depth !== 0">
        <div class="text-tips" i18n>
          This API Request is using <b>{{ model.authType }}</b> from
          <a (click)="nav2group()">{{ parentGroup?.name }}</a>
        </div>
      </ng-container>
      <ng-container *ngIf="!isDefaultAuthType">
        <eo-ng-feedback-alert class="block my-[20px]" nzType="warning" [nzMessage]="templateRefMsg" nzShowIcon></eo-ng-feedback-alert>
        <ng-template #templateRefMsg>
          <div class="text" i18n>
            These parameters hold sensitive data. To keep this data secure while working in a collaborative environment, we recommend using
            variables. Learn more about
            <a href="https://docs.postcat.com/docs/global-variable.html" target="_blank" rel="noopener noreferrer">variables</a>
          </div>
        </ng-template>
      </ng-container>

      <ng-container *ngIf="schemaObj">
        <eo-schema-form #schemaForm [model]="model.authInfo" [configuration]="schemaObj" (valueChanges)="handleValueChanges($event)" />
      </ng-container>
    </div>
  `
})
export class AuthorizationExtensionFormComponent implements OnInit, OnChanges {
  @Input() type: 'group' | 'api' = 'group';
  @Input() model: AuthInfo = {
    authType: '',
    authInfo: {}
  };
  @Input() groupID: number;
  @Output() readonly modelChange = new EventEmitter<AuthInfo>();
  @ViewChild('schemaForm') schemaForm: EoSchemaFormComponent;
  currGroup: Group;
  parentGroup: Group;
  inheritAuth = inheritAuth;
  schemaObj: Record<string, any> | null;
  authAPIMap: Map<string, FeatureInfo>;

  get authType() {
    return this.parentGroup?.depth ? inheritAuth : noAuth;
  }

  get isDefaultAuthType() {
    return [inheritAuth.name, noAuth.name].includes(this.model.authType);
  }

  get authTypeList() {
    return [this.authType, ...this.extensionList];
  }

  extensionList: Array<typeof noAuth> = [];

  constructor(private apiService: ApiService, private router: Router, private extensionService: ExtensionService) {}

  ngOnInit(): void {
    this.model.authType = this.groupID ? inheritAuth.name : noAuth.name;
    this.initExtensions();
  }

  initExtensions() {
    this.authAPIMap = this.extensionService.getValidExtensionsByFature('authAPI');
    console.log('authAPIMap', this.authAPIMap);
    this.extensionList = [];
    this.authAPIMap.forEach((value, key) => {
      this.extensionList.push({ name: key, label: value.label });
    });
  }

  async ngOnChanges(changes: SimpleChanges) {
    const { groupID } = changes;
    if (groupID?.currentValue !== groupID?.previousValue) {
      await this.getGroupInfo(this.groupID);
      if (this.currGroup.depth === 0 && this.model.authType === inheritAuth.name) {
        this.model.authType = noAuth.name;
      } else if (this.isDefaultAuthType) {
        this.model.authType = this.authType.name;
      }
      this.modelChange.emit(this.model);
    }
  }

  async getGroupInfo(groupID) {
    try {
      if (!groupID) {
        this.model.authType = this.authType.name;
        this.model.authInfo = {};
        return;
      }

      const [currGroup]: any = await this.apiService.api_groupDetail({ id: groupID });
      this.currGroup = currGroup;
      this.model.authType = currGroup.authInfo?.authType || this.authType.name;
      this.model.authInfo = JSONParse(currGroup.authInfo?.authInfo || {});
      this.handleAuthTypeChange(this.model.authType);
      this.modelChange.emit(this.model);
      if (this.type === 'group') {
        const [parentGroup]: any = await this.apiService.api_groupDetail({ id: currGroup.parentId });
        this.parentGroup = parentGroup;
      } else {
        this.parentGroup = currGroup;
      }
    } catch (error) {
      console.log('error', error);
    }
  }

  handleValueChanges(values) {
    console.log('handleValueChanges', values);
  }
  handleAuthTypeChange(authType) {
    if (this.authAPIMap.has(authType)) {
      this.schemaObj = this.authAPIMap.get(authType).configuration;
    } else {
      this.schemaObj = null;
    }
    console.log('handleAuthTypeChange', authType);
  }

  nav2group() {
    if (this.currGroup.depth === 0) {
      return;
    }
    this.router.navigate([`/home/workspace/project/api/group/edit`], {
      queryParams: { groupId: this.parentGroup.id, pageID: Date.now().toString() }
    });
  }
}
