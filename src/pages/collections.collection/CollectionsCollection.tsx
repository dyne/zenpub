// View a Collection (with list of resources)

import * as React from 'react';

import { Trans } from '@lingui/macro';

import { Grid, Row, Col } from '@zendeskgarden/react-grid';
import P from '../../components/typography/P/P';
import styled from '../../themes/styled';
import Main from '../../components/chrome/Main/Main';
import ResourceCard from '../../components/elements/Resource/Resource';
import { graphql, GraphqlQueryControls, OperationOption } from 'react-apollo';
import Collection from '../../types/Collection';
import { compose, withState, withHandlers } from 'recompose';
import { RouteComponentProps } from 'react-router';
import Loader from '../../components/elements/Loader/Loader';
import Breadcrumb from './breadcrumb';
import Button from '../../components/elements/Button/Button';
import CollectionModal from '../../components/elements/CollectionModal';
import EditCollectionModal from '../../components/elements/EditCollectionModal';
const getCollection = require('../../graphql/getCollection.graphql');
import H2 from '../../components/typography/H2/H2';
import Join from '../../components/elements/Collection/Join';
import Discussion from '../../components/chrome/Discussion/DiscussionCollection';
import { Settings, Resource, Message } from '../../components/elements/Icons';
import { SuperTab, SuperTabList } from '../../components/elements/SuperTab';
import { Tabs, TabPanel } from 'react-tabs';

import media from 'styled-media-query';

enum TabsEnum {
  // Members = 'Members',
  Resources = 'Resources',
  Discussion = 'Discussion'
}

interface Data extends GraphqlQueryControls {
  collection: Collection;
}

interface Props
  extends RouteComponentProps<{
      community: string;
      collection: string;
    }> {
  data: Data;
  addNewResource(): boolean;
  isOpen: boolean;
  editCollection(): boolean;
  isEditCollectionOpen: boolean;
}

class CollectionComponent extends React.Component<Props> {
  state = {
    tab: TabsEnum.Resources
  };

  render() {
    let collection;
    let resources;
    // let discussions;
    if (this.props.data.error) {
      collection = null;
    } else if (this.props.data.loading) {
      return <Loader />;
    } else {
      collection = this.props.data.collection;
      resources = this.props.data.collection.resources;
    }
    if (!collection) {
      // TODO better handling of no collection
      return (
        <span>
          <Trans>Could not load the collection.</Trans>
        </span>
      );
    }

    let community_name = collection.community.name;

    return (
      <>
        <Main>
          <Grid>
            <WrapperCont>
              <HeroCont>
                <Breadcrumb
                  community={{
                    id: collection.community.localId,
                    name: collection.community.name
                  }}
                  collectionName={collection.name}
                />
                <Hero>
                  <Background
                    style={{ backgroundImage: `url(${collection.icon})` }}
                  />
                  <HeroInfo>
                    <H2>{collection.name}</H2>
                    <P>
                      {collection.summary.split('\n').map(function(item, key) {
                        return (
                          <span key={key}>
                            {item}
                            <br />
                          </span>
                        );
                      })}
                    </P>
                    <ActionsHero>
                      <HeroJoin>
                        <Join
                          followed={collection.followed}
                          id={collection.localId}
                          externalId={collection.id}
                        />
                      </HeroJoin>
                      {collection.community.followed ? (
                        <EditButton onClick={this.props.editCollection}>
                          <Settings
                            width={18}
                            height={18}
                            strokeWidth={2}
                            color={'#f98012'}
                          />
                          <Trans>Edit collection</Trans>
                        </EditButton>
                      ) : null}
                    </ActionsHero>
                  </HeroInfo>
                </Hero>
                <Actions />
              </HeroCont>
              <Roww>
                <Col size={12}>
                  <WrapperTab>
                    <OverlayTab>
                      <Tabs>
                        <SuperTabList>
                          <SuperTab>
                            <span>
                              <Resource
                                width={20}
                                height={20}
                                strokeWidth={2}
                                color={'#a0a2a5'}
                              />
                            </span>
                            <h5>
                              {TabsEnum.Resources} (
                              {collection.resources.totalCount}
                              /10)
                            </h5>
                          </SuperTab>
                          <SuperTab>
                            <span>
                              <Message
                                width={20}
                                height={20}
                                strokeWidth={2}
                                color={'#a0a2a5'}
                              />
                            </span>{' '}
                            <h5>Discussions</h5>
                          </SuperTab>
                        </SuperTabList>

                        <TabPanel>
                          <div
                            style={{
                              display: 'flex',
                              flexWrap: 'wrap'
                            }}
                          >
                            <Wrapper>
                              {resources.totalCount ? (
                                <CollectionList>
                                  {resources.edges.map((edge, i) => (
                                    <ResourceCard
                                      key={i}
                                      icon={edge.node.icon}
                                      title={edge.node.name}
                                      summary={edge.node.summary}
                                      url={edge.node.url}
                                      localId={edge.node.localId}
                                    />
                                  ))}
                                </CollectionList>
                              ) : (
                                <OverviewCollection>
                                  <P>
                                    <Trans>
                                      This collection has no resources.
                                    </Trans>
                                  </P>
                                  {/* <Button onClick={this.props.addNewResource}>
                                  <Trans>Add the first resource</Trans>
                                </Button> */}
                                </OverviewCollection>
                              )}

                              {resources.totalCount > 9 ? null : collection
                                .community.followed ? (
                                <WrapperActions>
                                  <Button onClick={this.props.addNewResource}>
                                    <Trans>Add a new resource</Trans>
                                  </Button>
                                </WrapperActions>
                              ) : (
                                <Footer>
                                  <Trans>
                                    Join the <strong>{community_name}</strong>{' '}
                                    community to add a resource
                                  </Trans>
                                </Footer>
                              )}
                            </Wrapper>
                          </div>
                        </TabPanel>
                        <TabPanel>
                          {collection.community.followed ? (
                            <Discussion
                              localId={collection.localId}
                              id={collection.id}
                              threads={collection.threads}
                              followed
                            />
                          ) : (
                            <>
                              <Discussion
                                localId={collection.localId}
                                id={collection.id}
                                threads={collection.threads}
                              />
                              <Footer>
                                <Trans>
                                  Join the <strong>{community_name}</strong>{' '}
                                  community to participate in discussions
                                </Trans>
                              </Footer>
                            </>
                          )}
                        </TabPanel>
                      </Tabs>
                    </OverlayTab>
                  </WrapperTab>
                </Col>
              </Roww>
            </WrapperCont>
          </Grid>
          <CollectionModal
            toggleModal={this.props.addNewResource}
            modalIsOpen={this.props.isOpen}
            collectionId={collection.localId}
            collectionExternalId={collection.id}
          />
          <EditCollectionModal
            toggleModal={this.props.editCollection}
            modalIsOpen={this.props.isEditCollectionOpen}
            collectionId={collection.localId}
            collectionExternalId={collection.id}
            collection={collection}
          />
        </Main>
      </>
    );
  }
}

const ActionsHero = styled.div`
  margin-top: 4px;
  & div {
    &:hover {
      background: transparent;
    }
  }
`;
const HeroJoin = styled.div`
  float: left;
`;

const Roww = styled(Row)`
  height: 100%;
`;

const Actions = styled.div``;
const Footer = styled.div`
  height: 30px;
  line-height: 30px;
  font-weight: 600;
  text-align: center;
  background: #ffefd9;
  font-size: 13px;
  border-bottom: 1px solid #e4dcc3;
  color: #544f46;
`;

const WrapperCont = styled.div`
  max-width: 1040px;
  margin: 0 auto;
  width: 100%;
  display: flex;
  flex-direction: column;
  // height: 100%;

  box-sizing: border-box;
`;
// const Members = styled.div`
//   display: grid;
//   grid-template-columns: 1fr 1fr 1fr 1fr;
//   grid-column-gap: 8px;
//   grid-row-gap: 8px;
// `;
// const Follower = styled.div``;
// const Img = styled.div`
//   width: 40px;
//   height: 40px;
//   border-radius: 100px;
//   margin: 0 auto;
//   display: block;
// `;
// const FollowerName = styled(H4)`
//   margin-top: 8px;
//   text-align: center;
// `;

const EditButton = styled.span`
  color: #ff9d00;
  height: 40px;
  font-weight: 600;
  font-size: 13px;
  line-height: 38px;
  margin-left: 24px;
  cursor: pointer;
  display: inline-block;
  & svg {
    margin-top: 8px;
    text-align: center;
    vertical-align: text-bottom;
    margin-right: 8px;
  }
`;
const WrapperTab = styled.div`
  display: flex;
  flex: 1;
  height: 100%;
  border-radius: 6px;
  height: 100%;
  box-sizing: border-box;
  border: 5px solid #e2e5ea;
`;
const OverlayTab = styled.div`
  background: #fff;
  height: 100%;
  width: 100%;

  & > div {
    flex: 1;
    height: 100%;
  }
`;
const HeroInfo = styled.div`
  flex: 1;
  margin-left: 16px;
  & h2 {
    margin: 0;
    line-height: 32px !important;
    font-size: 24px !important;

    ${media.lessThan('medium')`
      margin-top: 8px;
    `};
  }
  & p {
    margin: 0;
    color: rgba(0, 0, 0, 0.8);
    font-size: 15px;
    margin-top: 8px;
  }
  & div {
    text-align: left;
    padding: 0;
  }
`;
const HeroCont = styled.div`
  margin-bottom: 16px;
  border-radius: 6px;
  box-sizing: border-box;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
  background: #fff;
`;

const WrapperActions = styled.div`
  margin: 8px;
  & button {
    ${media.lessThan('medium')`
   width: 100%;
    `};
  }
`;

const Wrapper = styled.div`
  flex: 1;
`;

const CollectionList = styled.div`
  flex: 1;
  margin: 10px;
`;

const OverviewCollection = styled.div`
  padding: 8px;
  & p {
    margin-top: 14px !important;
    font-size: 14px;
  }
`;

const Hero = styled.div`
  display: flex;
  width: 100%;
  position: relative;
  padding: 16px;
  ${media.lessThan('medium')`
  text-align: center;
  display: block;
`};
`;

const Background = styled.div`
  height: 120px;
  width: 120px;
  border-radius: 4px;
  background-size: cover;
  background-repeat: no-repeat;
  background-color: #e6e6e6;
  position: relative;
  margin: 0 auto;
`;

const withGetCollection = graphql<
  {},
  {
    data: {
      collection: Collection;
    };
  }
>(getCollection, {
  options: (props: Props) => ({
    variables: {
      id: Number(props.match.params.collection)
    }
  })
}) as OperationOption<{}, {}>;

export default compose(
  withGetCollection,
  withState('isOpen', 'onOpen', false),
  withState('isEditCollectionOpen', 'onEditCollectionOpen', false),
  withHandlers({
    addNewResource: props => () => props.onOpen(!props.isOpen),
    editCollection: props => () =>
      props.onEditCollectionOpen(!props.isEditCollectionOpen)
  })
)(CollectionComponent);
