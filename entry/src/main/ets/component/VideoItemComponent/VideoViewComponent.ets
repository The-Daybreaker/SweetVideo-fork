import { VideoList, VideoListController } from './VideoItemComponent';
import { VideoMetadata } from '../../interfaces/VideoMetadataInterface';
import { SideBarController } from '../SideBarComponent/SideBar';
import { ButtonFancyModifier, ShadowModifier, SymbolGlyphFancyModifier } from '../../utils/AttributeModifierUtil';
import { PathUtils } from '../../utils/PathUtils';
import SelectFileUtil from '../../utils/SelectFileUtil';
import ToolsUtil from '../../utils/ToolsUtil';
import { MenuModifier, SymbolGlyphModifier } from '@kit.ArkUI';
import DataSyncUtil from '../../utils/DataSyncUtil';
import { FileFolderDataSource } from '../../utils/DataUtil';
import { FileFolderMenu } from '../FileFolderComponent/FileFolderMenu';
import { MaskComponent } from '../SideBarComponent/MaskComponent';
import { SearchComponent } from './SearchComponent';
import { FolderOperator, VideoMetaDataOperator } from '../../database/VideoMetaData';

@Component
export struct VideoView {
  searchController: SearchController = new SearchController()
  @Prop loading: boolean = false
  @State is_edit: boolean = false
  @Link searchValue: string
  @Prop passwd: string = ''
  @Link videoListController: VideoListController
  @Consume sideBarController: SideBarController
  @Consume('pathStack') pathStack: NavPathStack
  @Consume fileFolderSource: FileFolderDataSource
  @StorageProp('topSafeHeight') topSafeHeight: number = 0;
  @StorageProp('bottomSafeHeight') bottomSafeHeight: number = 0;

  build() {
    Stack({ alignContent: Alignment.Top }) { // 内容区
      if (this.sideBarController.mask_state &&
        this.sideBarController.side_bar_mode === SideBarContainerType.Overlay) {
        MaskComponent()
      }
      Column() {
        VideoList({
          videoListController: this.videoListController
        })
      }

      if (this.videoListController.videoDataSource.totalCount() == 0) {
        Row() { //顶栏
          if (!this.loading) {
            Column() {
              Text($r('app.string.nothing')).fontSize(25).fontWeight(FontWeight.Bold)
              Text($r('app.string.open_side_bar_tip'))
                .fontSize(15)
                .textAlign(TextAlign.Center)
                .fontWeight(FontWeight.Lighter)
                .margin({ top: 20 })
            }
          }
        }
        .height('100%')
        .animation({ duration: 150, curve: Curve.Ease })
      }

      Column() {
        Row({ space: 15 }) {
          if (!this.is_edit && this.sideBarController.side_bar_mode == SideBarContainerType.Overlay) {
            Button({ type: ButtonType.Circle, stateEffect: true }) {
              SymbolGlyph($r('sys.symbol.close_sidebar'))
                .attributeModifier(new SymbolGlyphFancyModifier(25, '', ''))
            }
            .attributeModifier(new ButtonFancyModifier(40, 40))
            .animation({ duration: 300, curve: Curve.Ease })
            .onClick(() => {
              this.sideBarController.openSideBar()
            })
            .attributeModifier(new ShadowModifier())
            .zIndex(0)
          }

          SearchComponent({
            controller: this.searchController,
            placeholder: $r('app.string.search_placeholder'),
            searchValue: this.searchValue,
            onChange: () => {
              if (this.searchValue === '') {
                const videoMetaDataList: VideoMetadata[] =
                  FolderOperator.getFolderByName(this.videoListController.folder.name).video_list
                this.videoListController.videoDataSource.updateData(videoMetaDataList)
                this.videoListController.updateData(this.videoListController.videoDataSource,
                  this.videoListController.folder)
              } else {
                const videoMetaDataList: VideoMetadata[] =
                  SelectFileUtil.getItemFromSearch(FolderOperator.getFolderByName(this.videoListController.folder.name)
                    .video_list, this.searchValue)
                this.videoListController.videoDataSource.updateData(videoMetaDataList)
                this.videoListController.updateData(this.videoListController.videoDataSource,
                  this.videoListController.folder)
              }
            },
            onSubmit: (value: string) => {
              if (value == '') {
                if (this.videoListController.videoMetaDataList.length == 0) {
                  ToolsUtil.showToast(PathUtils.appContext!.resourceManager.getStringSync($r('app.string.add_video_first')))
                  return
                }
                this.searchController.stopEditing()
                return
              }
              if (value == this.passwd) {
                ToolsUtil.showToast(PathUtils.appContext!
                  .resourceManager.getStringSync($r('app.string.enter_privacy_space')))
                this.pathStack.pushPathByName('PrivacySpace', null)
                this.searchValue = ''
                return
              }
              if (this.videoListController.videoMetaDataList.length == 0) {
                ToolsUtil.showToast(PathUtils.appContext!.resourceManager.getStringSync($r('app.string.no_search_result')))
              }
            },
            onEditChange: (isEditing: boolean) => {
              animateToImmediately({ duration: 300, curve: Curve.Ease }, () => {
                this.is_edit = isEditing
              })
            }
          })

          if (!this.is_edit) {
            Button({ type: ButtonType.Circle, stateEffect: true }) {
              SymbolGlyph($r('sys.symbol.text_and_arrow_down'))
                .attributeModifier(new SymbolGlyphFancyModifier(25, '', ''))
            }
            .attributeModifier(new ButtonFancyModifier(40, 40))
            .animation({ duration: 300, curve: Curve.Ease })
            .bindMenu(this.SortMenuBuilder)
            .attributeModifier(new ShadowModifier())
            .zIndex(0)

            if (this.videoListController.multipleChooseState === Visibility.Visible) {
              Button({ type: ButtonType.Circle, stateEffect: true }) {
                SymbolGlyph($r('sys.symbol.checkmark_square_on_square'))
                  .attributeModifier(new SymbolGlyphFancyModifier(25, '', ''))
              }
              .attributeModifier(new ButtonFancyModifier(40, 40))
              .animation({ duration: 300, curve: Curve.Ease })
              .bindMenu(this.SelectItemMenuBuilder)
              .attributeModifier(new ShadowModifier())
              .zIndex(0)
            }
          }
        }
      }
      .padding({ top: this.topSafeHeight, left: 10, right: 10 })
      .width('100%')

    }
  }

  @Builder
  SortMenuBuilder() {
    Menu() {
      MenuItem({
        symbolStartIcon: new SymbolGlyphModifier($r('sys.symbol.textformat')),
        content: $r('app.string.sort_by_name')
      })
        .onClick(async () => {
          const videoMetaDataList =
            await ToolsUtil.sortByName(PathUtils.appContext!, this.videoListController.videoMetaDataList,
              undefined) as VideoMetadata[]
          this.videoListController.videoDataSource.updateData(videoMetaDataList)
        })
      MenuItem({
        symbolStartIcon: new SymbolGlyphModifier($r('sys.symbol.clock')),
        content: $r('app.string.sort_by_time')
      })
        .onClick(async () => {
          const videoMetaDataList =
            await ToolsUtil.sortByTime(PathUtils.appContext!, this.videoListController.videoMetaDataList,
              undefined) as VideoMetadata[]
          this.videoListController.videoDataSource.updateData(videoMetaDataList)
        })
    }.attributeModifier(new MenuModifier())
  }

  @Builder
  SelectItemMenuBuilder() {
    Menu() {
      MenuItem({
        symbolStartIcon: new SymbolGlyphModifier($r('sys.symbol.xmark')),
        content: $r('app.string.cancel')
      })
        .onClick(() => {
          this.videoListController.closeMultipleChoose()
          DataSyncUtil.delMultipleList.length = 0
        })
      MenuItem({
        symbolStartIcon: new SymbolGlyphModifier($r('sys.symbol.checkmark_square_on_square')),
        content: $r('app.string.select_all')
      })
        .onClick(() => {
          this.videoListController.itemMultipleChoose = !this.videoListController.itemMultipleChoose
          DataSyncUtil.delMultipleList.length = 0
          DataSyncUtil.delMultipleList = this.videoListController.videoMetaDataList
        })
      MenuItem({
        symbolStartIcon: new SymbolGlyphModifier($r('sys.symbol.trash_fill')),
        content: $r('app.string.delete_selected')
      })
        .onClick(async () => {
          this.videoListController.closeMultipleChoose()
          this.videoListController.multipleChooseState = Visibility.None;
          if (DataSyncUtil.delMultipleList.length > 0) {
            this.videoListController.videoDataSource.refreshData(this.videoListController.folder)
            const deletePromises = DataSyncUtil.delMultipleList.map(item => {
              return new Promise<void>(() => {
                DataSyncUtil.editingVideo = JSON.stringify(item);
                VideoMetaDataOperator.deleteItem(this.videoListController, this.fileFolderSource)
              });
            });
            await Promise.all(deletePromises);
          }
        })
      MenuItem({
        symbolStartIcon: new SymbolGlyphModifier($r('sys.symbol.arrow_right_folder_circle')),
        content: "添加到文件夹",
        builder: (): void => this.FileFolderMenuBuilder(undefined)
      })
    }.attributeModifier(new MenuModifier())
  }

  @Builder
  FileFolderMenuBuilder(video_item: VideoMetadata | undefined) {
    FileFolderMenu({ video_item: video_item })
  }
}