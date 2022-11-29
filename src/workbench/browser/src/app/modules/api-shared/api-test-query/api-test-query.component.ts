import { Component, OnInit, Input, OnChanges, Output, EventEmitter, OnDestroy } from '@angular/core';

import { Subject, takeUntil } from 'rxjs';
import { debounceTime } from 'rxjs/operators';

import { ApiTestQuery } from '../../../pages/api/service/api-test/api-test.model';
import { ApiTableService } from '../api-table.service';
import { ApiTestUtilService } from '../api-test-util.service';

@Component({
  selector: 'eo-api-test-query',
  templateUrl: './api-test-query.component.html',
  styleUrls: ['./api-test-query.component.scss'],
})
export class ApiTestQueryComponent implements OnInit, OnDestroy {
  @Input() model: ApiTestQuery[];
  @Input() disabled: boolean;
  @Output() modelChange: EventEmitter<any> = new EventEmitter();

  listConf: any = {
    column: [],
    setting: {},
  };
  itemStructure: ApiTestQuery = {
    required: true,
    name: '',
    value: '',
  };

  private modelChange$: Subject<void> = new Subject();
  private destroy$: Subject<void> = new Subject();

  constructor(private apiTable: ApiTableService) {
    this.modelChange$.pipe(debounceTime(300), takeUntil(this.destroy$)).subscribe(() => {
      this.modelChange.emit(this.model);
    });
  }

  ngOnInit(): void {
    this.initListConf();
  }
  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }
  private initListConf() {
    const config = this.apiTable.initTable({
      in: 'header',
      isEdit: true,
    });
    this.listConf.columns = config.columns;
    this.listConf.setting = config.setting;
  }
}
