import { Component, OnInit } from '@angular/core';
import { getGlobals } from 'eo/workbench/browser/src/app/pages/api/service/api-test/api-test.utils';
import { StoreService } from 'eo/workbench/browser/src/app/shared/store/state.service';
import { RemoteService } from 'eo/workbench/browser/src/app/shared/services/storage/remote.service';
import { Environment } from '../../../shared/services/storage/index.model';
import { computed, autorun, reaction } from 'mobx';
import { EffectService } from 'eo/workbench/browser/src/app/shared/store/effect.service';

@Component({
  selector: 'env-list',
  template: ` <div style="width:400px" class="preview pb-4">
    <span class="flex items-center px-6 h-12 title" i18n>Global variable</span>
    <div *ngIf="gloablParams.length" class="flex items-center justify-between px-6 h-8">
      <span class="px-1 w-1/3 text-gray-400">Name</span>
      <span class="px-1 w-2/3 text-gray-400">Value</span>
    </div>
    <div *ngFor="let it of gloablParams" class="flex items-center justify-between px-6 h-8">
      <span class="px-1 w-1/3  text-ellipsis overflow-hidden" [title]="it.name">{{ it.name }}</span>
      <span class="px-1 w-2/3  text-ellipsis overflow-hidden" [title]="it.value">{{ it.value }}</span>
    </div>
    <span *ngIf="!gloablParams.length" class="flex items-center px-6 h-12 text-gray-400" i18n>No Global variables</span>
    <div *ngIf="renderEnv?.uuid">
      <div *ngIf="renderEnv.hostUri">
        <span class="flex items-center px-6 h-12 title" i18n>Environment Host</span>
        <div>
          <span class="text-ellipsis overflow-hidden flex items-center px-6 h-12">{{ renderEnv.hostUri }}</span>
        </div>
      </div>
      <span class="flex items-center px-6 h-12 title" *ngIf="renderEnv.parameters?.length" i18n
        >Environment Global variable</span
      >
      <div class="flex items-center justify-between px-6 h-8">
        <span class="px-1 w-1/3 text-gray-400">Name</span>
        <span class="px-1 w-2/3 text-gray-400">Value</span>
      </div>
      <div *ngFor="let it of renderEnv.parameters" class="flex items-center justify-between px-6 h-8">
        <span class="px-1 w-1/3 text-ellipsis overflow-hidden" [title]="it.name">{{ it.name }}</span>
        <span class="px-1 w-2/3 text-ellipsis overflow-hidden" [title]="it.value">{{ it.value }}</span>
      </div>
    </div>
  </div>`,
  styleUrls: ['./env-list.component.scss'],
})
export class EnvListComponent implements OnInit {
  gloablParams: any = [];
  renderEnv: Environment = {
    name: '',
    projectID: -1,
    hostUri: '',
    parameters: [],
  };
  constructor(private store: StoreService) {}
  ngOnInit() {
    autorun(() => {
      this.renderEnv = this.store.getEnvList
        .map((it) => ({
          ...it,
          parameters: it.parameters.filter((item) => item.name || item.value),
        }))
        .find((it: any) => it.uuid === this.store.getCurrentEnv?.uuid);
    });
    this.gloablParams = this.getGlobalParams();
  }
  getGlobalParams() {
    return Object.entries(getGlobals() || {}).map((it) => {
      const [key, value] = it;
      return { name: key, value };
    });
  }
}
