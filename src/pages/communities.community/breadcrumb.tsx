import * as React from 'react';
import { SFC } from 'react';
import { Trans } from '@lingui/macro';
import Link from '../../components/elements/Link/Link';
import styled from '../../themes/styled';
import { Helmet } from 'react-helmet';

interface Props {
  name: string;
}

const Breadcrumb: SFC<Props> = ({ name }) => (
  <Main>
    <Helmet>
      <title>MoodleNet > Community > {name}</title>
    </Helmet>
    <Link to="/communities">
      <Trans>Communities</Trans>
    </Link>
    {' > '}
    <span>{name}</span>
  </Main>
);

export const Main = styled.div`
  font-size: 12px;
  font-weight: 700;
  text-decoration: none;
  text-transform: uppercase;
  line-height: 30px;
  background: ${props => props.theme.styles.colour.breadcrumb};
  border-bottom: ${props => props.theme.styles.colour.divider};
  padding: 0 8px;
  border-top-left-radius: 6px;
  border-top-right-radius: 6px;
  color: ${props => props.theme.styles.colour.base1} !important;
  & a {
    font-size: 12px;
    font-weight: 700;
    text-decoration: none;
    text-transform: uppercase;
    margin-right: 6px;
    color: ${props => props.theme.styles.colour.base1} !important;
  }
  & span {
    font-size: 12px;
    font-weight: 500;
    text-decoration: none;
    text-transform: uppercase;
    margin-left: 6px;
    color: ${props => props.theme.styles.colour.base6};
  }
`;

export default Breadcrumb;