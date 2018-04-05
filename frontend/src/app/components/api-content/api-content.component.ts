import { Component, Input } from '@angular/core';
import { Router } from '@angular/router';
import { Observable } from 'rxjs/Observable';
import { ErrorObservable } from 'rxjs/observable/ErrorObservable';
import { map, catchError } from 'rxjs/operators';

// zql imports
import { FunctionParamUpdate } from '../../models';
import { ApiService } from '../../pages/api/api.service';

@Component({
  selector: 'zql-api-content',
  styleUrls: ['./api-content.component.scss'],
  template: `
  <div class="toolbar">
    <mat-toolbar class="api-header" color="primary">
      <span class="flex-span"></span>
      <span>{{ functionData.name }}</span>
      <span class="flex-span"></span>
      <button mat-raised-button color="accent" type="button"
        (click)="testFunction(functionData.name, functionParamData)">Test</button>
    </mat-toolbar>
  </div>
  <div class="ng-content">
    <mat-card class="call-results" *ngIf="results || error">
      <mat-card-content>
        {{ results | json }}{{ error }}
      </mat-card-content>
    </mat-card>
    <mat-card>
      <mat-card-content>
        <p>{{ functionData.description }}</p>
      </mat-card-content>
      <mat-card-content>
        <ng-content></ng-content>
      </mat-card-content>
    </mat-card>
  </div>
  <zql-test-api
    [functionData]="functionData"
    (paramUpdated)="updateFunctionParams($event)">
  </zql-test-api>
  `
})
export class ApiContentComponent {
  @Input() functionData;
  public functionParamData: { [paramName: string]: string | string[] | string[][] } = {};
  public results$: Observable<any>;
  public results: string;
  public error: string;

  constructor(
    private router: Router,
    private api: ApiService
  ) {}

  public updateFunctionParams(functionParamUpdate: FunctionParamUpdate) {
    this.functionParamData[functionParamUpdate.name] = functionParamUpdate.data;
    console.log(functionParamUpdate);
  }

  public testFunction(functionName: string, functionParamData: { [paramName: string]: string | string[] | string[][] }) {
    this.results$ = this.api.callFunction(functionName, functionParamData);
    this.results$.pipe(
        map(data => data.status),
        catchError(err => {
          console.log(err);
          this.results = '';
          this.error = err.error.status;
          return ErrorObservable.create(err.error.status);
        })
      )
      .subscribe(data => {
        // TODO: adapt to summary stat return json
        // typeof data === 'object'
        console.log(data);
        this.error = '';
        this.results = data;
        this.api.queryTableNames();
      });
  }
}
